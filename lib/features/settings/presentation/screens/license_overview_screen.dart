import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/settings_section_card.dart';

class LicenseOverviewScreen extends StatefulWidget {
  const LicenseOverviewScreen({super.key, required this.applicationName});

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
        licensesByPackage
            .putIfAbsent(package, () => <String>[])
            .add(licenseText);
      }
    }

    final groups =
        licensesByPackage.entries
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PackageLicenseDetailScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(materialL10n.licensesPageTitle)),
      body: FutureBuilder<List<_PackageLicenseGroup>>(
        future: _licensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
              SettingsSectionCard(
                children: [
                  ListTile(
                    title: Text(widget.applicationName),
                    subtitle: const Text('Powered by Flutter'),
                  ),
                ],
              ),
              SettingsSectionCard(
                children: groups
                    .map((group) {
                      return ListTile(
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
                    })
                    .toList(growable: false),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PackageLicenseDetailScreen extends StatelessWidget {
  const _PackageLicenseDetailScreen({required this.group});

  final _PackageLicenseGroup group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.package)),
      body: ListView.builder(
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
    );
  }
}

class _PackageLicenseGroup {
  const _PackageLicenseGroup({required this.package, required this.licenses});

  final String package;
  final List<String> licenses;
}
