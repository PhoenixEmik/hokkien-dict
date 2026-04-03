#!/usr/bin/env python3
from __future__ import annotations

import argparse
import gzip
import json
import re
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from datetime import datetime, UTC
from pathlib import Path

TABLE_NS = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"
TEXT_NS = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
OFFICE_NS = "urn:oasis:names:tc:opendocument:xmlns:office:1.0"
NS = {
    "table": TABLE_NS,
    "text": TEXT_NS,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert the ministry Hokkien ODS database into a bundled JSON asset.",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("data/source/kautian.ods"),
        help="Path to the source ODS file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/data/dictionary.json.gz"),
        help="Path to the generated gzip-compressed JSON asset.",
    )
    return parser.parse_args()


def office_attr(name: str) -> str:
    return f"{{{OFFICE_NS}}}{name}"


def table_attr(name: str) -> str:
    return f"{{{TABLE_NS}}}{name}"


def cell_text(cell: ET.Element) -> str:
    paragraphs = [
        "".join(part.itertext()).strip()
        for part in cell.findall("text:p", NS)
    ]
    text_value = "\n".join(value for value in paragraphs if value).strip()
    if text_value:
        return text_value

    for attr_name in ("string-value", "date-value", "time-value", "value"):
        value = cell.attrib.get(office_attr(attr_name))
        if value:
            return value

    return ""


def expand_row(row: ET.Element, column_limit: int | None = None) -> list[str]:
    values: list[str] = []
    for cell in row.findall("table:table-cell", NS):
        repeat = int(cell.attrib.get(table_attr("number-columns-repeated"), "1"))
        value = cell_text(cell)
        if column_limit is not None:
            remaining = column_limit - len(values)
            if remaining <= 0:
                break
            repeat = min(repeat, remaining)
        values.extend([value] * repeat)

    if column_limit is not None and len(values) < column_limit:
        values.extend([""] * (column_limit - len(values)))

    return values


def iter_sheet_rows(table: ET.Element) -> tuple[list[str], list[dict[str, str]]]:
    rows = table.findall("table:table-row", NS)
    if not rows:
        return [], []

    headers = [header.strip() for header in expand_row(rows[0])]
    column_limit = len(headers)
    records: list[dict[str, str]] = []

    for row in rows[1:]:
        repeat = int(row.attrib.get(table_attr("number-rows-repeated"), "1"))
        values = expand_row(row, column_limit=column_limit)
        if not any(values):
            continue
        record = {
            header: value.strip()
            for header, value in zip(headers, values, strict=False)
        }
        records.extend([record.copy() for _ in range(repeat)])

    return headers, records


def read_tables(source_path: Path) -> dict[str, list[dict[str, str]]]:
    with zipfile.ZipFile(source_path) as archive:
        root = ET.fromstring(archive.read("content.xml"))

    tables: dict[str, list[dict[str, str]]] = {}
    for table in root.findall(".//table:table", NS):
        name = table.attrib.get(table_attr("name"))
        if not name:
            continue
        _, rows = iter_sheet_rows(table)
        tables[name] = rows
    return tables


def parse_int(value: str) -> int | None:
    if not value:
        return None
    try:
        return int(float(value))
    except ValueError:
        return None


def normalize_for_search(text: str) -> str:
    if not text:
        return ""

    normalized = unicodedata.normalize("NFKD", text.casefold())
    normalized = "".join(
        character
        for character in normalized
        if not unicodedata.combining(character)
    )
    normalized = normalized.replace("o\u0358", "oo")
    normalized = normalized.replace("ⁿ", "n")
    normalized = re.sub(r"[-_/]", " ", normalized)
    normalized = re.sub(r"[【】\[\]（）()、,.;:!?\"'`]+", " ", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized


def build_payload(source_path: Path) -> dict[str, object]:
    tables = read_tables(source_path)

    headwords: dict[int, dict[str, object]] = {}
    for row in tables["詞目"]:
        headword_id = parse_int(row.get("詞目id", ""))
        if headword_id is None:
            continue
        headwords[headword_id] = {
            "id": headword_id,
            "type": row.get("詞目類型", ""),
            "hanji": row.get("漢字", ""),
            "romanization": row.get("羅馬字", ""),
            "category": row.get("分類", ""),
            "audio": row.get("羅馬字音檔檔名", ""),
            "senses": [],
        }

    sense_index: dict[tuple[int, int], dict[str, object]] = {}
    for row in tables["義項"]:
        headword_id = parse_int(row.get("詞目id", ""))
        sense_id = parse_int(row.get("義項id", ""))
        if headword_id is None or sense_id is None:
            continue
        sense = {
            "id": sense_id,
            "partOfSpeech": row.get("詞性", ""),
            "definition": row.get("解說", ""),
            "examples": [],
        }
        entry = headwords.get(headword_id)
        if entry is None:
            continue
        cast_senses = entry["senses"]
        assert isinstance(cast_senses, list)
        cast_senses.append(sense)
        sense_index[(headword_id, sense_id)] = sense

    example_count = 0
    for row in tables["例句"]:
        headword_id = parse_int(row.get("詞目id", ""))
        sense_id = parse_int(row.get("義項id", ""))
        if headword_id is None or sense_id is None:
            continue
        sense = sense_index.get((headword_id, sense_id))
        if sense is None:
            continue
        examples = sense["examples"]
        assert isinstance(examples, list)
        examples.append(
            {
                "order": parse_int(row.get("例句順序", "")) or 0,
                "hanji": row.get("漢字", ""),
                "romanization": row.get("羅馬字", ""),
                "mandarin": row.get("華語", ""),
                "audio": row.get("音檔檔名", ""),
            }
        )
        example_count += 1

    entries: list[dict[str, object]] = []
    sense_count = 0
    for entry in sorted(headwords.values(), key=lambda item: int(item["id"])):
        senses = entry["senses"]
        assert isinstance(senses, list)
        sense_count += len(senses)

        mandarin_segments: list[str] = []
        for sense in senses:
            assert isinstance(sense, dict)
            definition = sense.get("definition", "")
            if isinstance(definition, str) and definition:
                mandarin_segments.append(definition)

            examples = sense.get("examples", [])
            assert isinstance(examples, list)
            for example in examples:
                assert isinstance(example, dict)
                mandarin = example.get("mandarin", "")
                if isinstance(mandarin, str) and mandarin:
                    mandarin_segments.append(mandarin)

        hokkien_segments = [
            str(entry.get("hanji", "")),
            str(entry.get("romanization", "")),
            str(entry.get("category", "")),
        ]
        entry["hokkienSearch"] = normalize_for_search(" ".join(hokkien_segments))
        entry["mandarinSearch"] = normalize_for_search(" ".join(mandarin_segments))
        entries.append(entry)

    return {
        "source": "https://sutian.moe.edu.tw/media/senn/ods/kautian.ods",
        "generatedAt": datetime.now(UTC).isoformat(),
        "entryCount": len(entries),
        "senseCount": sense_count,
        "exampleCount": example_count,
        "entries": entries,
    }


def write_payload(payload: dict[str, object], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    with gzip.open(output_path, "wt", encoding="utf-8") as gz_file:
        gz_file.write(content)


def main() -> None:
    args = parse_args()
    payload = build_payload(args.source)
    write_payload(payload, args.output)
    print(
        f"Generated {args.output} with {payload['entryCount']} entries, "
        f"{payload['senseCount']} senses, and {payload['exampleCount']} examples.",
    )


if __name__ == "__main__":
    main()
