import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/reference_articles.dart';
import '../widgets/settings_section_card.dart';
import 'license_summary_screen.dart';
import 'reference_article_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<void> _openRepository() async {
    await launchUrl(
      Uri.parse(AppConstants.appRepositoryUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openLicenseSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LicenseSummaryScreen(),
      ),
    );
  }

  void _openReferenceArticle(
    BuildContext context, {
    required LocalizedReferenceArticle article,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReferenceArticleScreen(
          title: article.title,
          introduction: article.introduction,
          sections: article.sections,
          sourceUrl: article.sourceUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsSectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.appTitle),
                subtitle: Text(l10n.aboutDescription),
              ),
              ListTile(
                leading: const Icon(Icons.tag_outlined),
                title: Text(l10n.aboutVersion),
                subtitle: const Text(AppConstants.appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.aboutAuthor),
                subtitle: const Text(AppConstants.appAuthor),
              ),
              Semantics(
                label:
                    '${l10n.aboutRepository}。${AppConstants.appRepositoryUrl}',
                button: true,
                onTap: () {
                  unawaited(_openRepository());
                },
                child: ExcludeSemantics(
                  child: ListTile(
                    leading: const Icon(Icons.code_outlined),
                    title: Text(l10n.aboutRepository),
                    subtitle: const Text(AppConstants.appRepositoryUrl),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      unawaited(_openRepository());
                    },
                  ),
                ),
              ),
            ],
          ),
          SettingsSectionCard(
            children: [
              Semantics(
                label:
                    '${l10n.aboutLicenses}。${l10n.flutterLicensesDescription}',
                button: true,
                onTap: () {
                  _openLicenseSummary(context);
                },
                child: ExcludeSemantics(
                  child: ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(l10n.aboutLicenses),
                    subtitle: Text(l10n.flutterLicensesDescription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openLicenseSummary(context);
                    },
                  ),
                ),
              ),
              Semantics(
                label: '${l10n.privacyPolicy}。${l10n.privacyPolicySubtitle}',
                button: true,
                onTap: () {
                  _openReferenceArticle(
                    context,
                    article: buildPrivacyPolicyArticle(l10n),
                  );
                },
                child: ExcludeSemantics(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.privacyPolicy),
                    subtitle: Text(l10n.privacyPolicySubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openReferenceArticle(
                        context,
                        article: buildPrivacyPolicyArticle(l10n),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SettingsSectionCard(
            title: l10n.aboutResources,
            children: [
              ListTile(
                title: Text(l10n.referencePage),
                subtitle: const SelectableText(
                  'https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
                ),
              ),
              ListTile(
                title: Text(l10n.tailoGuide),
                subtitle: const SelectableText(
                  'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
                ),
              ),
              ListTile(
                title: Text(l10n.hanjiGuide),
                subtitle: const SelectableText(
                  'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
