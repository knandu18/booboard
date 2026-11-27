// SPDX-License-Identifier: GPL-3.0-or-later
//
// MDICT: BooBoard's compact, versioned dictionary file format (version 1).
//
// A `.mdict` file is a 4-byte magic `MDZ1` followed by a zlib stream of the
// payload below, or just the raw payload (magic `MDCT`) for tests. All
// integers are little-endian.
//
//   header
//     "MDCT"                 4 bytes magic
//     u8   version           = 1
//     u8   flags             bit0: keys fold accents (café -> cafe)
//     u16  reserved
//     u32  wordCount         n
//     u32  trieLen
//     u32  rootOffset        offset of the root node inside the trie section
//     u32  wordsLen
//     u32  bigramCount
//     u32  bigramDataLen     = bigramCount * 4
//     u32  correctionsLen
//     u8   langLen, then langLen bytes of ASCII language id
//   sections, in this order
//     trie            packed trie over the folded keys (see below)
//     words           n records, one per word id: u8 len, u8 q, u8 flags, then
//                     len bytes of UTF-8 surface form (the display spelling)
//     wordIndex       u32 byte offset into `words` of every 64th record
//     bigramCounts    n bytes: how many successors each word has (<= 255)
//     bigramData      per word id, its successors sorted by id:
//                     u24 successor id, u8 q
//     corrections     UTF-8 text "typed<TAB>target" lines (apostrophe-less
//                     contractions and common typos that are always fixed)
//
// Word ids are the index of the folded key in sorted (code unit) order, so a
// depth-first walk visits terminal nodes in id order.
//
// Probabilities are quantised: logProb = -q / 10, q in 0..255 (q 0 = p 1).
//
// Trie node (offsets are relative to the start of the trie section):
//   u8   flags       bit0 terminal, bit1 offensive
//   u8   childCount  0..255
//   u8   bestQ       lowest q of any word in this subtree, including itself
//   [terminal only]  u24 word id, u8 q
//   childCount * { u16 key char, u24 child offset }   sorted by key char
//
// Children are written before their parent, so the root is the last node.
import 'dart:typed_data';

const int kMdictVersion = 1;
const String kMdictMagicRaw = 'MDCT';
const String kMdictMagicZlib = 'MDZ1';

/// Quantisation step of stored log probabilities.
const double kQStep = 0.1;
const int kQMax = 255;

const int kNodeTerminal = 1;
const int kNodeOffensive = 2;
const int kWordIndexStride = 64;
const int kHeaderFixedLen = 4 + 1 + 1 + 2 + 4 * 7 + 1;

int quantizeLogProb(double logProb) {
  final q = (-logProb / kQStep).round();
  return q < 0 ? 0 : (q > kQMax ? kQMax : q);
}

double dequantize(int q) => -q * kQStep;

int readU24(Uint8List d, int o) => d[o] | (d[o + 1] << 8) | (d[o + 2] << 16);
int readU16(Uint8List d, int o) => d[o] | (d[o + 1] << 8);
int readU32(Uint8List d, int o) => d[o] | (d[o + 1] << 8) | (d[o + 2] << 16) | (d[o + 3] << 24);
