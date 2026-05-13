import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';

import '../widgets/settings_section_card.dart';
import 'license_overview_screen.dart';

class LicenseSummaryScreen extends StatelessWidget {
  const LicenseSummaryScreen({super.key});

  void _openFlutterLicenses(BuildContext context, AppLocalizations l10n) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LicenseOverviewScreen(applicationName: l10n.appTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.licenseInformation)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsSectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.code_outlined),
                title: Text(l10n.appCodeLicense),
                subtitle: Text(l10n.appCodeLicenseDescription),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(l10n.dictionaryDataLicense),
                subtitle: Text(l10n.dictionaryDataLicenseDescription),
              ),
              ListTile(
                leading: const Icon(Icons.volume_up_outlined),
                title: Text(l10n.dictionaryAudioLicense),
                subtitle: Text(l10n.dictionaryAudioLicenseDescription),
              ),
              ListTile(
                leading: const Icon(Icons.copyright_outlined),
                title: Text(l10n.ministryCopyrightNote),
                subtitle: const SelectableText(
                  'https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/',
                ),
              ),
            ],
          ),
          SettingsSectionCard(
            children: [
              Semantics(
                label:
                    '${l10n.flutterLicenses}。${l10n.flutterLicensesDescription}',
                button: true,
                onTap: () {
                  _openFlutterLicenses(context, l10n);
                },
                child: ExcludeSemantics(
                  child: ListTile(
                    leading: const Icon(Icons.flutter_dash_outlined),
                    title: Text(l10n.flutterLicenses),
                    subtitle: Text(l10n.flutterLicensesDescription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openFlutterLicenses(context, l10n);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
