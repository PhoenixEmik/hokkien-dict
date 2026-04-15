import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taigi_dict/core/core.dart';

import '../widgets/notification.dart';
import 'license_summary_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  void _copyRepositoryUrl(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(const ClipboardData(text: AppConstants.appRepositoryUrl));
    showAppNotification(context, message: l10n.copiedToClipboard);
  }

  void _openLicenseSummary(BuildContext context) {
    Navigator.of(context).push(
      PlatformInfo.isIOS
          ? CupertinoPageRoute<void>(
              builder: (_) => const LicenseSummaryScreen(),
            )
          : MaterialPageRoute<void>(
              builder: (_) => const LicenseSummaryScreen(),
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
      appBar: AdaptiveAppBar(title: l10n.aboutApp, useNativeToolbar: true),
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AdaptiveFormSection.insetGrouped(
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.appTitle),
                  subtitle: Text(l10n.aboutDescription),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.tag_outlined),
                  title: Text(l10n.aboutVersion),
                  subtitle: const Text(AppConstants.appVersion),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.aboutAuthor),
                  subtitle: const Text(AppConstants.appAuthor),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(l10n.aboutRepository),
                  subtitle: const Text(AppConstants.appRepositoryUrl),
                  trailing: const Icon(Icons.copy_outlined),
                  onTap: () {
                    _copyRepositoryUrl(context, l10n);
                  },
                ),
              ],
            ),
            AdaptiveFormSection.insetGrouped(
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l10n.aboutLicenses),
                  subtitle: Text(l10n.flutterLicensesDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _openLicenseSummary(context);
                  },
                ),
              ],
            ),
            AdaptiveFormSection.insetGrouped(
              header: Text(l10n.aboutResources),
              children: [
                AdaptiveListTile(
                  title: Text(l10n.referencePage),
                  subtitle: const SelectableText(
                    'https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
                  ),
                ),
                AdaptiveListTile(
                  title: Text(l10n.tailoGuide),
                  subtitle: const SelectableText(
                    'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
                  ),
                ),
                AdaptiveListTile(
                  title: Text(l10n.hanjiGuide),
                  subtitle: const SelectableText(
                    'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
