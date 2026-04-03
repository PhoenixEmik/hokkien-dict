# 台語辭典

Flutter dictionary app for iOS and Android, built from the Ministry of Education
Taiwanese Hokkien dataset:

- Source ODS: `https://sutian.moe.edu.tw/media/senn/ods/kautian.ods`
- App behavior: offline Hokkien → Mandarin and Mandarin → Hokkien lookup
- Bundled asset: `assets/data/dictionary.json.gz`

## License

- App code: MIT. See `LICENSE`.
- Dictionary data: `CC BY-NC-ND 2.5 TW`. See `DATA_LICENSE.md`.

## Project Structure

- `lib/main.dart`: app UI, asset loading, and search logic
- `tool/build_dictionary_asset.py`: converts the ODS database into the bundled gzip JSON asset
- `data/source/kautian.ods`: downloaded source spreadsheet

## Regenerate Dictionary Data

If the upstream ODS changes, rebuild the packaged dictionary asset:

```bash
python3 tool/build_dictionary_asset.py
```

## Run

```bash
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## Delivery Notes

- Android and iOS app display names are set to `台語辭典`.
- The generated Flutter project still uses the default example bundle/application identifiers.
  Update the Android `applicationId` and iOS bundle identifier before store delivery.
- Release signing is not configured yet. Add your own Android keystore and Apple signing settings
  before publishing.
