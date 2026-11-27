// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-B. Review what BooBoard learned for one language: search, sort, forget a word, never
// suggest it again, or clear the language. Shown with FLAG_SECURE (no screenshots, no recents).
//
// PRIVACY: words are displayed only here. Nothing is logged.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/data_sections.dart';
import '../../engine/learn/learned_data.dart';
import '../../security/app_auth.dart';
import '../app_services.dart';
import 'privacy_format.dart';
import 'privacy_widgets.dart';

import 'package:booboard/src/app/l10n.dart';

class LearnedWordsScreen extends StatefulWidget {
  const LearnedWordsScreen({super.key, required this.languageId});

  /// Language code, such as `en`. The blob is `learned_<languageId>`.
  final String languageId;

  @override
  State<LearnedWordsScreen> createState() => _LearnedWordsScreenState();
}

enum _Sort { score, alphabetical }

enum _WordAction { forget, block }

enum _MoreAction { clearLanguage }

class _Loaded {
  const _Loaded({required this.data, required this.locked});

  /// Null when the language has nothing stored.
  final LearnedData? data;

  /// True when stored data exists but cannot be read right now (locked phone or changed key).
  final bool locked;
}

class _LearnedWordsScreenState extends State<LearnedWordsScreen> {
  AppServices? _services;
  Future<_Loaded>? _future;
  String _query = '';
  _Sort _sort = _Sort.score;

  String get _blobName => DataBlobs.learned(widget.languageId);

  @override
  void initState() {
    super.initState();
    SecureScreenGuard.instance.acquire();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = _services = AppScope.of(context);
    _future = _load(services);
  }

  @override
  void dispose() {
    SecureScreenGuard.instance.release();
    super.dispose();
  }

  Future<_Loaded> _load(AppServices services) async {
    final bytes = await services.secureStore.read(_blobName);
    final exists = (await services.platform.secureList()).any((b) => b.name == _blobName);
    if (bytes == null && exists) return const _Loaded(data: null, locked: true);
    if (bytes == null) return const _Loaded(data: null, locked: false);
    return _Loaded(data: LearnedData.decode(widget.languageId, bytes), locked: false);
  }

  void _retry() {
    final services = _services;
    if (services == null) return;
    setState(() => _future = _load(services));
  }

  /// Writes the blob, then tells the keyboard to reload it.
  Future<void> _save(LearnedData data) async {
    final services = _services!;
    try {
      await services.secureStore.write(_blobName, data.encode());
      await services.notifyDataChanged(const [DataSections.learned]);
    } on Object {
      if (mounted) showPrivacyMessage(context, context.l10n.privacySaveFailed);
    }
    if (mounted) setState(() {});
  }

  Future<void> _act(LearnedData data, String key, _WordAction action) async {
    if (action == _WordAction.block) data.blocked.add(key);
    data.removeWord(key);
    await _save(data);
  }

  Future<void> _unblock(LearnedData data, String key) async {
    data.blocked.remove(key);
    data.dirty = true;
    await _save(data);
  }

  Future<void> _clearLanguage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.privacyClearLanguageTitle(languageName(widget.languageId))),
        content: Text(context.l10n.privacyClearLanguageBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.privacyClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final services = _services!;
    await services.secureStore.delete(_blobName);
    await services.notifyDataChanged(const [DataSections.learned]);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.privacyLearnedWordsTitle(languageName(widget.languageId));
    return FutureBuilder<_Loaded>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Message(title: title, text: context.l10n.privacyCouldNotReadWords, onRetry: _retry);
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final loaded = snapshot.requireData;
        if (loaded.locked) {
          return _Message(title: title, text: context.l10n.privacyCannotReadWordsNow, onRetry: _retry);
        }
        final data = loaded.data;
        if (data == null) {
          return _Message(title: title, text: context.l10n.privacyNoWordsLanguage);
        }
        return _body(title, data);
      },
    );
  }

  Widget _body(String title, LearnedData data) {
    final today = dayNumber(DateTime.now());
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final e in data.words.entries)
        if (query.isEmpty || e.value.surface.toLowerCase().contains(query)) e,
    ];
    if (_sort == _Sort.score) {
      visible.sort((a, b) => b.value.scoreAt(today).compareTo(a.value.scoreAt(today)));
    } else {
      visible.sort((a, b) => a.value.surface.toLowerCase().compareTo(b.value.surface.toLowerCase()));
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: context.l10n.privacyBlockedWordsTooltip(data.blocked.length),
            icon: const Icon(Icons.block),
            onPressed: () => _showBlocked(data),
          ),
          PopupMenuButton<_Sort>(
            tooltip: context.l10n.privacySortTooltip,
            icon: Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (context) => [
              PopupMenuItem(value: _Sort.score, child: Text(context.l10n.privacySortMostUsed)),
              PopupMenuItem(value: _Sort.alphabetical, child: Text(context.l10n.privacySortAZ)),
            ],
          ),
          PopupMenuButton<_MoreAction>(
            tooltip: context.l10n.privacyMoreTooltip,
            onSelected: (action) {
              if (action == _MoreAction.clearLanguage) unawaited(_clearLanguage());
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: _MoreAction.clearLanguage, child: Text(context.l10n.privacyClearThisLanguage)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: context.l10n.privacySearchWords,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.privacyWordsSummary(
                  context.l10n.countWords(data.words.length),
                  context.l10n.countBlockedWords(data.blocked.length),
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        query.isEmpty
                            ? context.l10n.privacyNoWordsYet
                            : context.l10n.privacyNoWordsMatch(_query.trim()),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final entry = visible[i];
                      final word = entry.value;
                      return _WordTile(
                        word: word,
                        wordKey: entry.key,
                        today: today,
                        onAction: (action) => unawaited(_act(data, entry.key, action)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlocked(LearnedData data) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final blocked = data.blocked.toList()..sort();
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(context.l10n.privacyNeverSuggested, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(context.l10n.privacyBlockedExplain),
                const SizedBox(height: 8),
                if (blocked.isEmpty) Text(context.l10n.privacyNoBlockedWords),
                for (final key in blocked)
                  ListTile(
                    title: Text(key),
                    trailing: TextButton(
                      onPressed: () async {
                        await _unblock(data, key);
                        setSheet(() {});
                      },
                      child: Text(context.l10n.privacyAllowAgain),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.wordKey, required this.today, required this.onAction});

  final LearnedWord word;
  final String wordKey;
  final int today;
  final ValueChanged<_WordAction> onAction;

  @override
  Widget build(BuildContext context) {
    final days = today - word.day;
    final when = days <= 0
        ? context.l10n.privacyToday
        : (days == 1 ? context.l10n.privacyYesterday : context.l10n.timeDaysAgo(days));
    final known = word.commits >= kCommitsToKnow;
    final detail = known
        ? context.l10n.privacyWordLastUsed(word.commits, when)
        : context.l10n.privacyWordNotYetSuggested(when);
    return ListTile(
      title: Text(word.surface),
      subtitle: Text(detail),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      trailing: PopupMenuButton<_WordAction>(
        tooltip: context.l10n.privacyActionsFor(word.surface),
        onSelected: onAction,
        itemBuilder: (context) => [
          PopupMenuItem(value: _WordAction.forget, child: Text(context.l10n.privacyForgetWord)),
          PopupMenuItem(value: _WordAction.block, child: Text(context.l10n.privacyNeverSuggestWord)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.text, this.onRetry});

  final String title;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(context.l10n.privacyTryAgain)),
            ],
          ],
        ),
      ),
    ),
  );
}
