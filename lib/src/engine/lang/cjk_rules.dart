// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned, Wave 4): rules shared by Chinese and Japanese. Words are not
// separated by spaces, there is no case, and the full-width marks end sentences. chinese.dart and
// japanese.dart may subclass this for their own quotes and punctuation.
import '../contracts.dart';

class CjkRules implements LanguageRules {
  const CjkRules(this.language, {this.quotes = ('“', '”')});

  @override
  final LanguageId language;

  @override
  final (String, String) quotes;

  static final RegExp _word = RegExp(r"[\p{L}\p{M}\p{Nd}'’\-ー]", unicode: true);

  @override
  bool get hasCase => false;

  @override
  bool isWordChar(String char) => _word.hasMatch(char);

  @override
  bool removesSpaceBefore(String punctuation) => const {
    '.', ',', '!', '?', ':', ';', ')', ']', '}', '%', //
    '。', '，', '、', '！', '？', '：', '；', '）', '」', '』', '】', '》',
  }.contains(punctuation);

  @override
  String? spaceBefore(String punctuation) => null;

  /// Never: Chinese and Japanese text has no spaces after punctuation.
  @override
  bool addsSpaceAfter(String punctuation) => false;

  @override
  bool endsSentence(String punctuation) => const {'。', '！', '？', '.', '!', '?'}.contains(punctuation);
}
