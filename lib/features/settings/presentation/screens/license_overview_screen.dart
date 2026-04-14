import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LicenseOverviewScreen extends StatefulWidget {
  const LicenseOverviewScreen({
    super.key,
    required this.applicationName,
  });

  final String applicationName;

  @override
  State<LicenseOverviewScreen> createState() => _LicenseOverviewScreenState();
}

class _LicenseOverviewScreenState extends State<LicenseOverviewScreen> {
  late final Future<List<_PackageLicenseGroup>> _licensesFuture =
      _loadPackageLicenses();

  Future<List<_PackageLicenseGroup>> _loadPackageLicenses() async {
    final licensesByPackage = <String, List<String>>{};

    await for (final entry in LicenseRegistry.licenses) {
      final paragraphs = entry.paragraphs
          .map((paragraph) => paragraph.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(growable: false);
      if (paragraphs.isEmpty) {
        continue;
      }

      final licenseText = paragraphs.join('\n\n');
      for (final package in entry.packages) {
        licensesByPackage.putIfAbsent(package, () => <String>[]).add(licenseText);
      }
    }

    final groups = licensesByPackage.entries
        .map(
          (entry) => _PackageLicenseGroup(
            package: entry.key,
            licenses: List<String>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.package.compareTo(b.package));

    return groups;
  }

  void _openPackageLicense(BuildContext context, _PackageLicenseGroup group) {
    final route = Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoPageRoute<void>(
            builder: (_) => PackageLicenseDetailScreen(group: group),
          )
        : MaterialPageRoute<void>(
            builder: (_) => PackageLicenseDetailScreen(group: group),
          );
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;
    final materialL10n = MaterialLocalizations.of(context);

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: materialL10n.licensesPageTitle,
        useNativeToolbar: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: FutureBuilder<List<_PackageLicenseGroup>>(
          future: _licensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    materialL10n.alertDialogLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final groups = snapshot.data ?? const <_PackageLicenseGroup>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                AdaptiveFormSection.insetGrouped(
                  children: [
                    AdaptiveListTile(
                      title: Text(widget.applicationName),
                      subtitle: const Text('Powered by Flutter'),
                    ),
                  ],
                ),
                AdaptiveFormSection.insetGrouped(
                  children: groups.map((group) {
                    return AdaptiveListTile(
                      title: Text(group.package),
                      subtitle: Text(
                        materialL10n.licensesPackageDetailText(
                          group.licenses.length,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _openPackageLicense(context, group);
                      },
                    );
                  }).toList(growable: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PackageLicenseDetailScreen extends StatelessWidget {
  const PackageLicenseDetailScreen({
    super.key,
    required this.group,
  });

  final _PackageLicenseGroup group;

  @override
  Widget build(BuildContext context) {
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: group.package,
        useNativeToolbar: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: group.licenses.length,
          itemBuilder: (context, index) {
            final license = group.licenses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(license),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PackageLicenseGroup {
  const _PackageLicenseGroup({
    required this.package,
    required this.licenses,
  });

  final String package;
  final List<String> licenses;
}
