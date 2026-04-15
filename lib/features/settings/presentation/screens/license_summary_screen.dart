import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';

import 'license_overview_screen.dart';

class LicenseSummaryScreen extends StatelessWidget {
  const LicenseSummaryScreen({super.key});

  void _openFlutterLicenses(BuildContext context, AppLocalizations l10n) {
    Navigator.of(context).push(
      PlatformInfo.isIOS
          ? CupertinoPageRoute<void>(
              builder: (_) =>
                  LicenseOverviewScreen(applicationName: l10n.appTitle),
            )
          : MaterialPageRoute<void>(
              builder: (_) =>
                  LicenseOverviewScreen(applicationName: l10n.appTitle),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: l10n.licenseInformation,
        useNativeToolbar: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AdaptiveFormSection.insetGrouped(
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(l10n.appCodeLicense),
                  subtitle: Text(l10n.appCodeLicenseDescription),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(l10n.dictionaryDataLicense),
                  subtitle: Text(l10n.dictionaryDataLicenseDescription),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: Text(l10n.dictionaryAudioLicense),
                  subtitle: Text(l10n.dictionaryAudioLicenseDescription),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.copyright_outlined),
                  title: Text(l10n.ministryCopyrightNote),
                  subtitle: const SelectableText(
                    'https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/',
                  ),
                ),
              ],
            ),
            AdaptiveFormSection.insetGrouped(
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.flutter_dash_outlined),
                  title: Text(l10n.flutterLicenses),
                  subtitle: Text(l10n.flutterLicensesDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _openFlutterLicenses(context, l10n);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
