// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. About: version, booboard.com (opens in the browser; the app itself never uses the
// network), the GPL-3.0 licence, the source code link (selectable text), and every licence.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import '../onboarding/booboard_mascot.dart';
import '../screens/home_screen.dart' show booboardWebsite;
import 'notices.dart';

import 'package:booboard/src/app/l10n.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Future<AppInfoMessage>? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _info ??= AppScope.of(context).platform.getAppInfo();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppInfoMessage>(
    future: _info,
    builder: (context, snapshot) {
      final info = snapshot.data;
      final version = info == null
          ? context.l10n.aboutReadingVersion
          : 'Version ${info.versionName} (${info.versionCode})${info.isDebugBuild ? ' · debug build' : ''}';
      return SettingsPage(
        title: context.l10n.settingsAbout,
        header: SettingsHero(mascot: BooBoardMascot(size: 72), title: context.l10n.appName, subtitle: version),
        children: [
          SettingsGroup(
            title: context.l10n.settingsPrivacy,
            children: [
              SettingsTile(
                icon: Icons.wifi_off_outlined,
                title: context.l10n.aboutNoInternet,
                subtitle: context.l10n.aboutNoInternetBody,
              ),
            ],
          ),
          SettingsGroup(
            children: [
              Semantics(
                hint: context.l10n.websiteOpenHint,
                child: SettingsTile(
                  icon: Icons.public,
                  title: context.l10n.aboutWebsite,
                  subtitle: booboardWebsite,
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => unawaited(_openWebsite(context)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.aboutLicence,
            children: [
              SettingsTile(
                icon: Icons.gavel_outlined,
                title: context.l10n.aboutGplTitle,
                subtitle: context.l10n.aboutGplBody,
                onTap: () => _openNotice(context, BooBoardNotices.all.first),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.aboutSourceCode,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: booboardSourceCodeUrl.isEmpty
                    ? Text(context.l10n.aboutSourceBody, style: Theme.of(context).textTheme.bodyMedium)
                    : SelectableText(booboardSourceCodeUrl, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.aboutLicences,
            children: [
              SettingsTile(
                icon: Icons.article_outlined,
                title: context.l10n.aboutOpenSource,
                subtitle: context.l10n.aboutOpenSourceBody,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: context.l10n.appName,
                  applicationVersion: info?.versionName,
                ),
              ),
              for (final notice in BooBoardNotices.all.skip(1))
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: notice.title,
                  onTap: () => _openNotice(context, notice),
                ),
            ],
          ),
        ],
      );
    },
  );

  /// Opens booboard.com in the browser (the app itself never goes online).
  Future<void> _openWebsite(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.websiteNoBrowser;
    try {
      await AppScope.of(context).app.openWebsite();
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openNotice(BuildContext context, BooBoardNotice notice) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NoticeTextPage(title: notice.title, asset: notice.asset),
        ),
      ),
    );
  }
}

/// The full text of one licence or notice file, selectable.
class NoticeTextPage extends StatelessWidget {
  const NoticeTextPage({super.key, required this.title, required this.asset});

  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<String>(
      future: rootBundle.loadString(asset),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.aboutTextLoadFailed));
        }
        final text = snapshot.data;
        if (text == null) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: SelectableText(text, style: Theme.of(context).textTheme.bodySmall),
        );
      },
    ),
  );
}
