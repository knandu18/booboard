// SPDX-License-Identifier: GPL-3.0-or-later
//
// TalkBack labels for conversion candidates (strip and grid). The label says the candidate, its
// note and its position, so "Candidate 你好, 1 of 12" tells a user where they are in the list.
import '../input/composer.dart';

String candidateSemanticsLabel(ComposerCandidate c, {required int index, required int total}) {
  final note = c.annotation == null || c.annotation!.isEmpty ? '' : ', ${c.annotation}';
  return 'Candidate ${c.text}$note, ${index + 1} of $total';
}
