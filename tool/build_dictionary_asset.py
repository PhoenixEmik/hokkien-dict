#!/usr/bin/env python3
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from collections import defaultdict
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

TABLE_NS = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"
TEXT_NS = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
OFFICE_NS = "urn:oasis:names:tc:opendocument:xmlns:office:1.0"
NS = {
    "table": TABLE_NS,
    "text": TEXT_NS,
}

SOURCE_URL = "https://app.taigidict.org/assets/kautian.ods"
SCHEMA_VERSION = 1

VARIANT_SHEET = "異用字"
SENSE_TO_SENSE_SYNONYM_SHEET = "義項tuì義項近義"
SENSE_TO_SENSE_ANTONYM_SHEET = "義項tuì義項反義"
SENSE_TO_WORD_SYNONYM_SHEET = "義項tuì詞目近義"
SENSE_TO_WORD_ANTONYM_SHEET = "義項tuì詞目反義"
WORD_TO_WORD_SYNONYM_SHEET = "詞目tuì詞目近義"
WORD_TO_WORD_ANTONYM_SHEET = "詞目tuì詞目反義"
ALTERNATIVE_PRONUNCIATION_SHEET = "又唸作"
CONTRACTED_PRONUNCIATION_SHEET = "合音唸作"
COLLOQUIAL_PRONUNCIATION_SHEET = "俗唸作"
PHONETIC_DIFFERENCES_SHEET = "語音差異"
VOCABULARY_COMPARISON_SHEET = "詞彙比較"
UNLISTED_RELATION_ENTRY_TYPE = "近反義詞不單列詞目者"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert the Taigi Dict ODS source into runtime-neutral JSON assets. "
            "The Swift rewrite consumes the JSONL package; the gzip JSON output "
            "is retained for the existing Flutter pipeline."
        ),
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("data/source/kautian.ods"),
        help="Path to the source ODS file.",
    )
    parser.add_argument(
        "--json-output",
        type=Path,
        default=Path("assets/data/dictionary.json.gz"),
        help="Path to the generated gzip-compressed JSON asset.",
    )
    parser.add_argument(
        "--package-output",
        type=Path,
        default=Path("ios-native/Generated/Dictionary"),
        help="Directory for dictionary_manifest.json and dictionary_entries.jsonl.",
    )
    parser.add_argument(
        "--skip-gzip-json",
        action="store_true",
        help="Only generate the Swift JSONL package.",
    )
    return parser.parse_args()


def office_attr(name: str) -> str:
    return f"{{{OFFICE_NS}}}{name}"


def table_attr(name: str) -> str:
    return f"{{{TABLE_NS}}}{name}"


def cell_text(cell: ET.Element) -> str:
    paragraphs = ["".join(part.itertext()).strip() for part in cell.findall("text:p", NS)]
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
        record = {header: value.strip() for header, value in zip(headers, values, strict=False)}
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


def require_sheet(tables: dict[str, list[dict[str, str]]], name: str) -> list[dict[str, str]]:
    if name not in tables:
        raise KeyError(f"Missing worksheet in ODS: {name}")
    return tables[name]


def optional_sheet(tables: dict[str, list[dict[str, str]]], name: str) -> list[dict[str, str]]:
    return tables.get(name, [])


def parse_int(value: str | None) -> int | None:
    if not value:
        return None
    try:
        return int(value)
    except ValueError:
        try:
            return int(float(value))
        except ValueError:
            return None


def normalize_for_search(text: str) -> str:
    if not text:
        return ""

    normalized = unicodedata.normalize("NFKD", text.casefold())
    normalized = "".join(character for character in normalized if not unicodedata.combining(character))
    normalized = normalized.replace("ⁿ", "n")
    normalized = re.sub(r"[1-8]", "", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    normalized = re.sub(r"[-_/]", " ", normalized)
    normalized = re.sub(r"[【】\[\]（）()、,.;:!?\"'`]+", " ", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized


def append_unique(target: dict[int, list[str]], key: int, value: str) -> None:
    trimmed = value.strip()
    if not trimmed:
        return
    items = target.setdefault(key, [])
    if trimmed not in items:
        items.append(trimmed)


def split_slash_separated_values(value: str) -> list[str]:
    return [part.strip() for part in value.split("/") if part.strip()]


def dedupe_preserving_order(values: list[str] | None) -> list[str]:
    if not values:
        return []
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        trimmed = value.strip()
        if not trimmed or trimmed in seen:
            continue
        seen.add(trimmed)
        result.append(trimmed)
    return result


def build_entries(source_path: Path) -> tuple[list[dict[str, Any]], int, int]:
    tables = read_tables(source_path)

    headword_rows = require_sheet(tables, "詞目")
    sense_rows = require_sheet(tables, "義項")
    example_rows = require_sheet(tables, "例句")
    variant_rows = optional_sheet(tables, VARIANT_SHEET)
    sense_to_sense_synonym_rows = optional_sheet(tables, SENSE_TO_SENSE_SYNONYM_SHEET)
    sense_to_sense_antonym_rows = optional_sheet(tables, SENSE_TO_SENSE_ANTONYM_SHEET)
    sense_to_word_synonym_rows = optional_sheet(tables, SENSE_TO_WORD_SYNONYM_SHEET)
    sense_to_word_antonym_rows = optional_sheet(tables, SENSE_TO_WORD_ANTONYM_SHEET)
    word_to_word_synonym_rows = optional_sheet(tables, WORD_TO_WORD_SYNONYM_SHEET)
    word_to_word_antonym_rows = optional_sheet(tables, WORD_TO_WORD_ANTONYM_SHEET)
    alternative_pronunciation_rows = optional_sheet(tables, ALTERNATIVE_PRONUNCIATION_SHEET)
    contracted_pronunciation_rows = optional_sheet(tables, CONTRACTED_PRONUNCIATION_SHEET)
    colloquial_pronunciation_rows = optional_sheet(tables, COLLOQUIAL_PRONUNCIATION_SHEET)
    phonetic_differences_rows = optional_sheet(tables, PHONETIC_DIFFERENCES_SHEET)
    vocabulary_comparison_rows = optional_sheet(tables, VOCABULARY_COMPARISON_SHEET)

    entries_by_id: dict[int, dict[str, Any]] = {}
    entry_ids_by_hanji: dict[str, set[int]] = defaultdict(set)

    for row in headword_rows:
        entry_id = parse_int(row.get("詞目id"))
        if entry_id is None:
            continue
        entry = {
            "id": entry_id,
            "type": row.get("詞目類型", ""),
            "hanji": row.get("漢字", ""),
            "romanization": row.get("羅馬字", ""),
            "category": row.get("分類", ""),
            "audio": row.get("羅馬字音檔檔名", ""),
            "variantChars": [],
            "wordSynonyms": [],
            "wordAntonyms": [],
            "alternativePronunciations": [],
            "contractedPronunciations": [],
            "colloquialPronunciations": [],
            "phoneticDifferences": [],
            "vocabularyComparisons": [],
            "aliasTargetEntryId": None,
            "hokkienSearch": "",
            "mandarinSearch": "",
            "senses": [],
        }
        entries_by_id[entry_id] = entry
        if entry["hanji"]:
            entry_ids_by_hanji[str(entry["hanji"])].add(entry_id)

    sense_by_key: dict[tuple[int, int], dict[str, Any]] = {}
    entry_id_by_sense_id: dict[int, int] = {}
    mandarin_by_entry_id: dict[int, list[str]] = defaultdict(list)
    definition_synonyms_by_sense_id: dict[int, list[str]] = {}
    definition_antonyms_by_sense_id: dict[int, list[str]] = {}

    for row in sense_rows:
        entry_id = parse_int(row.get("詞目id"))
        sense_id = parse_int(row.get("義項id"))
        if entry_id is None or sense_id is None or entry_id not in entries_by_id:
            continue
        sense = {
            "_senseId": sense_id,
            "partOfSpeech": row.get("詞性", ""),
            "definition": row.get("解說", ""),
            "definitionSynonyms": [],
            "definitionAntonyms": [],
            "examples": [],
        }
        entries_by_id[entry_id]["senses"].append(sense)
        sense_by_key[(entry_id, sense_id)] = sense
        entry_id_by_sense_id[sense_id] = entry_id
        if sense["definition"]:
            mandarin_by_entry_id[entry_id].append(str(sense["definition"]))

    example_count = 0
    for row in example_rows:
        entry_id = parse_int(row.get("詞目id"))
        sense_id = parse_int(row.get("義項id"))
        if entry_id is None or sense_id is None:
            continue
        sense = sense_by_key.get((entry_id, sense_id))
        if sense is None:
            continue
        mandarin = row.get("華語", "")
        sense["examples"].append(
            {
                "order": parse_int(row.get("例句順序")) or 0,
                "hanji": row.get("漢字", ""),
                "romanization": row.get("羅馬字", ""),
                "mandarin": mandarin,
                "audio": row.get("音檔檔名", ""),
            }
        )
        if mandarin:
            mandarin_by_entry_id[entry_id].append(mandarin)
        example_count += 1

    def entry_is_unlisted_relation(entry_id: int) -> bool:
        return entries_by_id.get(entry_id, {}).get("type") == UNLISTED_RELATION_ENTRY_TYPE

    def register_alias_target(source_entry_id: int, target_entry_id: int) -> None:
        if (
            source_entry_id == target_entry_id
            or source_entry_id not in entries_by_id
            or target_entry_id not in entries_by_id
        ):
            return

        source_is_alias = entry_is_unlisted_relation(source_entry_id)
        target_is_alias = entry_is_unlisted_relation(target_entry_id)
        if source_is_alias == target_is_alias:
            return

        alias_entry_id = source_entry_id if source_is_alias else target_entry_id
        primary_entry_id = target_entry_id if source_is_alias else source_entry_id
        entries_by_id[alias_entry_id]["aliasTargetEntryId"] = entries_by_id[alias_entry_id].get(
            "aliasTargetEntryId"
        ) or primary_entry_id

    for row in variant_rows:
        entry_id = parse_int(row.get("詞目id"))
        variant = row.get("異用字", "")
        if entry_id is not None and entry_id in entries_by_id:
            append_unique(entries_by_id[entry_id], "variantChars", variant)

    def collect_sense_links(
        rows: list[dict[str, str]],
        target: dict[int, list[str]],
        target_word_column: str,
    ) -> None:
        for row in rows:
            sense_id = parse_int(row.get("義項id"))
            linked_word = row.get(target_word_column, "")
            source_entry_id = entry_id_by_sense_id.get(sense_id) if sense_id is not None else None
            target_entry_id = parse_int(row.get("對應詞目id"))
            if target_entry_id is None:
                target_entry_id = entry_id_by_sense_id.get(parse_int(row.get("對應義項id")))
            if sense_id is not None and linked_word and sense_id in entry_id_by_sense_id:
                append_unique(target, sense_id, linked_word)
            if source_entry_id is not None and target_entry_id is not None:
                register_alias_target(source_entry_id, target_entry_id)

    def collect_word_links(rows: list[dict[str, str]], target_key: str) -> None:
        for row in rows:
            entry_id = parse_int(row.get("詞目id"))
            target_entry_id = parse_int(row.get("對應詞目id"))
            linked_word = row.get("對應詞目漢字", "")
            if entry_id is not None and entry_id in entries_by_id:
                append_unique(entries_by_id[entry_id], target_key, linked_word)
            if entry_id is not None and target_entry_id is not None:
                register_alias_target(entry_id, target_entry_id)

    collect_sense_links(sense_to_sense_synonym_rows, definition_synonyms_by_sense_id, "對應詞目漢字")
    collect_sense_links(sense_to_word_synonym_rows, definition_synonyms_by_sense_id, "對應詞目漢字")
    collect_sense_links(sense_to_sense_antonym_rows, definition_antonyms_by_sense_id, "對應詞目漢字")
    collect_sense_links(sense_to_word_antonym_rows, definition_antonyms_by_sense_id, "對應詞目漢字")
    collect_word_links(word_to_word_synonym_rows, "wordSynonyms")
    collect_word_links(word_to_word_antonym_rows, "wordAntonyms")

    def collect_pronunciations(rows: list[dict[str, str]], target_key: str) -> None:
        for row in rows:
            entry_id = parse_int(row.get("詞目id"))
            romanization = row.get("羅馬字", "")
            if entry_id is not None and entry_id in entries_by_id:
                for value in split_slash_separated_values(romanization):
                    append_unique(entries_by_id[entry_id], target_key, value)

    collect_pronunciations(alternative_pronunciation_rows, "alternativePronunciations")
    collect_pronunciations(contracted_pronunciation_rows, "contractedPronunciations")
    collect_pronunciations(colloquial_pronunciation_rows, "colloquialPronunciations")

    for row in phonetic_differences_rows:
        entry_id = parse_int(row.get("詞目id"))
        if entry_id is None or entry_id not in entries_by_id:
            continue
        notes = [
            f"{header}：{value}"
            for header, value in row.items()
            if header not in ("", "詞目id", "漢字") and value
        ]
        if notes:
            entries_by_id[entry_id]["phoneticDifferences"] = notes

    for row in vocabulary_comparison_rows:
        hanji = row.get("漢字", "")
        entry_ids = entry_ids_by_hanji.get(hanji)
        if not hanji or not entry_ids:
            continue
        summary = "／".join(value for value in [row.get("華語詞目", ""), row.get("腔", "")] if value)
        romanization = row.get("羅馬字", "")
        line = "".join(
            [
                f"{summary}：" if summary else "",
                hanji,
                f"（{romanization}）" if romanization else "",
            ]
        )
        for entry_id in entry_ids:
            entries_by_id[entry_id].setdefault("vocabularyComparisons", []).append(line)

    entries: list[dict[str, Any]] = []
    sense_count = 0
    for entry_id in sorted(entries_by_id):
        entry = entries_by_id[entry_id]
        senses = sorted(entry["senses"], key=lambda sense: int(sense["_senseId"]))
        sense_count += len(senses)

        for sense in senses:
            sense_id = int(sense.pop("_senseId"))
            sense["definitionSynonyms"] = dedupe_preserving_order(definition_synonyms_by_sense_id.get(sense_id))
            sense["definitionAntonyms"] = dedupe_preserving_order(definition_antonyms_by_sense_id.get(sense_id))
            sense["examples"].sort(key=lambda item: (int(item.get("order", 0)), str(item.get("hanji", ""))))

        for key in (
            "variantChars",
            "wordSynonyms",
            "wordAntonyms",
            "alternativePronunciations",
            "contractedPronunciations",
            "colloquialPronunciations",
            "phoneticDifferences",
            "vocabularyComparisons",
        ):
            entry[key] = dedupe_preserving_order(entry.get(key))

        entry["senses"] = senses
        entry["hokkienSearch"] = normalize_for_search(
            " ".join(
                [
                    str(entry.get("hanji", "")),
                    str(entry.get("romanization", "")),
                    str(entry.get("category", "")),
                    *entry["variantChars"],
                    *entry["alternativePronunciations"],
                    *entry["contractedPronunciations"],
                    *entry["colloquialPronunciations"],
                ]
            )
        )
        entry["mandarinSearch"] = normalize_for_search(" ".join(mandarin_by_entry_id.get(entry_id, [])))
        if entry.get("aliasTargetEntryId") is None:
            entry.pop("aliasTargetEntryId", None)
        entries.append(entry)

    return entries, sense_count, example_count


def source_modified_at(source_path: Path) -> str:
    return datetime.fromtimestamp(source_path.stat().st_mtime, UTC).isoformat()


def build_payload(source_path: Path) -> dict[str, Any]:
    entries, sense_count, example_count = build_entries(source_path)
    return {
        "source": SOURCE_URL,
        "generatedAt": datetime.now(UTC).isoformat(),
        "sourceModifiedAt": source_modified_at(source_path),
        "entryCount": len(entries),
        "senseCount": sense_count,
        "exampleCount": example_count,
        "entries": entries,
    }


def write_gzip_payload(payload: dict[str, Any], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    with gzip.open(output_path, "wt", encoding="utf-8") as gz_file:
        gz_file.write(content)


def write_jsonl_package(payload: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    output_dir.mkdir(parents=True, exist_ok=True)
    entries_file_name = "dictionary_entries.jsonl"
    entries_path = output_dir / entries_file_name
    manifest_path = output_dir / "dictionary_manifest.json"

    entries = payload["entries"]
    assert isinstance(entries, list)
    with entries_path.open("w", encoding="utf-8", newline="\n") as entries_file:
        for entry in entries:
            entries_file.write(json.dumps(entry, ensure_ascii=False, separators=(",", ":")))
            entries_file.write("\n")

    entries_bytes = entries_path.read_bytes()
    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "builtAt": payload["generatedAt"],
        "source": SOURCE_URL,
        "sourceModifiedAt": payload["sourceModifiedAt"],
        "entryCount": payload["entryCount"],
        "senseCount": payload["senseCount"],
        "exampleCount": payload["exampleCount"],
        "entriesFileName": entries_file_name,
        "checksumSHA256": hashlib.sha256(entries_bytes).hexdigest(),
    }
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return manifest


def main() -> None:
    args = parse_args()
    payload = build_payload(args.source)
    if not args.skip_gzip_json:
        write_gzip_payload(payload, args.json_output)
    manifest = write_jsonl_package(payload, args.package_output)
    print(
        f"Generated {args.package_output} with {manifest['entryCount']} entries, "
        f"{manifest['senseCount']} senses, and {manifest['exampleCount']} examples.",
    )
    if not args.skip_gzip_json:
        print(f"Updated {args.json_output}.")


if __name__ == "__main__":
    main()
