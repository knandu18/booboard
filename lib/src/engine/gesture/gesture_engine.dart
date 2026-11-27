// SPDX-License-Identifier: GPL-3.0-or-later
//
// The synchronous swipe decoder core (runs inside the background isolate; also
// usable directly in tests and benchmarks).
//
// Approach: SHARK^2-style template matching (Kristensson & Zhai, UIST 2004).
// The gesture and each word's key-centre polyline are resampled to 64 points
// and compared on two channels, location (absolute distance in key widths)
// and shape (translation- and scale-normalised). The channels are combined as
// Gaussian log-likelihoods, plus a weighted language-model term. The
// statistical flavour follows FlorisBoard's StatisticalGlideTypingClassifier
// (Apache-2.0); no code was copied, see docs/notices/gesture.md.
import 'dart:math' as math;
import 'dart:typed_data';

import 'gesture_math.dart';
import 'template_index.dart';

/// Tunable constants of the scoring model.
class GestureTuning {
  const GestureTuning({
    this.sigmaLocation = 0.3,
    this.sigmaShape = 0.4,
    this.lambda = 0.3,
    this.endpointRadius = 1.2,
    this.minLengthRatio = 0.5,
    this.maxLengthRatio = 2.2,
    this.boundsTolerance = 1.6,
    this.maxMeanLocation = 1.8,
    this.endWeight = 6,
    this.sigmaEnd = 0.6,
    this.previewBucketCap = 90,
    this.previewEndpointRadius = 1.0,
  });

  /// Spread (in key widths) of the location channel's Gaussian.
  final double sigmaLocation;

  /// Spread (in key widths) of the shape channel's Gaussian.
  final double sigmaShape;

  /// Weight of the language-model log-probability against the geometry.
  final double lambda;

  /// Start/end key neighbourhood radius, in key widths.
  final double endpointRadius;
  final double minLengthRatio;
  final double maxLengthRatio;

  /// Allowed deviation of the bounding box, in key widths.
  final double boundsTolerance;

  /// Extra weight of the first and last points of the location channel: the
  /// first and last keys are the ones a finger hits most reliably.
  final double endWeight;

  /// Spread (in key widths) of the Gaussian on the first/last point distance.
  final double sigmaEnd;

  /// Hard cut-off for the mean location distance, in key widths.
  final double maxMeanLocation;

  /// Preview mode scans only the most frequent templates of each bucket.
  final int previewBucketCap;
  final double previewEndpointRadius;
}

class GestureEngine {
  GestureEngine({this.tuning = const GestureTuning()}) : _weights = _pointWeights(tuning.endWeight);

  final GestureTuning tuning;

  final Float64List _weights;
  GestureKeys? _keys;
  TemplateSet? _base;
  TemplateSet? _extras;

  // Scratch buffers, reused across calls.
  final Float64List _cleanX = Float64List(4096);
  final Float64List _cleanY = Float64List(4096);
  final Float64List _rx = Float64List(kGesturePoints);
  final Float64List _ry = Float64List(kGesturePoints);
  final Float64List _gnx = Float64List(kGesturePoints);
  final Float64List _gny = Float64List(kGesturePoints);
  final Int32List _startKeys = Int32List(16);
  final Int32List _endKeys = Int32List(16);

  bool get isReady => _keys != null && ((_base?.count ?? 0) + (_extras?.count ?? 0)) > 0;
  int get templateCount => (_base?.count ?? 0) + (_extras?.count ?? 0);
  int get approxBytes => (_base?.approxBytes ?? 0) + (_extras?.approxBytes ?? 0);

  void setKeys(GestureKeys keys) {
    _keys = keys;
    _base = null;
    _extras = null;
  }

  void buildBase(List<WordList> lists) {
    final keys = _keys;
    if (keys == null) return;
    _base = TemplateSet.build(keys, lists, learned: false);
  }

  void buildExtras(List<WordList> lists) {
    final keys = _keys;
    if (keys == null) return;
    _extras = lists.isEmpty ? null : TemplateSet.build(keys, lists, learned: true);
  }

  void clear() {
    _keys = null;
    _base = null;
    _extras = null;
  }

  /// Best candidates for a gesture given as interleaved coordinates
  /// `[x0, y0, x1, y1, ...]`. Returns an empty list for taps and very short
  /// paths. With [preview] set it scans fewer candidates for speed.
  List<RawCandidate> decode(Float64List xy, {int maxResults = 16, bool preview = false}) {
    final keys = _keys;
    if (keys == null || !isReady) return const [];
    final kw = keys.keyWidth;

    // 1. Clean: drop points closer than half a pixel to their predecessor.
    var n = 0;
    final raw = xy.length ~/ 2;
    for (var i = 0; i < raw && n < _cleanX.length; i++) {
      final x = xy[i * 2], y = xy[i * 2 + 1];
      if (n > 0) {
        final dx = x - _cleanX[n - 1], dy = y - _cleanY[n - 1];
        if (dx * dx + dy * dy < 0.25) continue;
      }
      _cleanX[n] = x;
      _cleanY[n] = y;
      n++;
    }
    if (n < 2) return const [];
    var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < n; i++) {
      final x = _cleanX[i], y = _cleanY[i];
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    final startKey = keys.nearest(_cleanX[0], _cleanY[0]);
    final endKey = keys.nearest(_cleanX[n - 1], _cleanY[n - 1]);
    final bboxDiag = math.sqrt((maxX - minX) * (maxX - minX) + (maxY - minY) * (maxY - minY));
    final gLen = resamplePolyline(_cleanX, _cleanY, n, kGesturePoints, _rx, _ry);
    // A one-key movement is a tap or a wobble, not a swipe.
    if (gLen < 1.0 * kw || bboxDiag < 0.9 * kw) return const [];
    if (startKey == endKey && bboxDiag < 1.4 * kw) return const [];

    // 2. Normalised shape of the gesture.
    var cx = 0.0, cy = 0.0;
    for (var k = 0; k < kGesturePoints; k++) {
      cx += _rx[k];
      cy += _ry[k];
    }
    cx /= kGesturePoints;
    cy /= kGesturePoints;
    final gd = math.max(1.0, bboxDiag);
    for (var k = 0; k < kGesturePoints; k++) {
      _gnx[k] = (_rx[k] - cx) / gd;
      _gny[k] = (_ry[k] - cy) / gd;
    }

    // 3. Pruning neighbourhoods around the first and last key.
    final radius = (preview ? tuning.previewEndpointRadius : tuning.endpointRadius) * kw;
    final ns = keys.neighbours(_rx[0], _ry[0], radius, _startKeys);
    final ne = keys.neighbours(_rx[kGesturePoints - 1], _ry[kGesturePoints - 1], radius, _endKeys);

    final k = preview ? 1 : maxResults;
    final top = _TopK(k);
    final cap = preview ? tuning.previewBucketCap : 1 << 30;
    final sets = [?_extras, ?_base];
    for (final set in sets) {
      for (var a = 0; a < ns; a++) {
        for (var b = 0; b < ne; b++) {
          _scanBucket(set, _startKeys[a] * keys.count + _endKeys[b], cap, gLen, minX, minY, maxX, maxY, gd, kw, top);
        }
      }
    }
    return top.results();
  }

  void _scanBucket(
    TemplateSet set,
    int bucket,
    int cap,
    double gLen,
    double gMinX,
    double gMinY,
    double gMaxX,
    double gMaxY,
    double gd,
    double kw,
    _TopK top,
  ) {
    final from = set.bucketStart[bucket];
    var to = set.bucketStart[bucket + 1];
    if (to - from > cap) to = from + cap;
    final items = set.bucketItems;
    final pts = set.points;
    final invQ = 1.0 / set.quant;
    final minRatio = tuning.minLengthRatio;
    final maxRatio = tuning.maxLengthRatio;
    final tol = tuning.boundsTolerance * kw;
    final invSigL2 = 1.0 / (2 * tuning.sigmaLocation * tuning.sigmaLocation);
    final invSigS2 = 1.0 / (2 * tuning.sigmaShape * tuning.sigmaShape);
    final invSigE2 = 1.0 / (2 * tuning.sigmaEnd * tuning.sigmaEnd);
    final lambda = tuning.lambda;
    final invKw = 1.0 / kw;
    final maxLocSum = tuning.maxMeanLocation * kw;
    const checkA = 20, checkB = 40;

    for (var it = from; it < to; it++) {
      final t = items[it];
      final ratio = gLen / set.length[t];
      if (ratio < minRatio || ratio > maxRatio) continue;
      final bo = t * 4;
      final bounds = set.bounds;
      if ((bounds[bo] - gMinX).abs() > tol ||
          (bounds[bo + 1] - gMinY).abs() > tol ||
          (bounds[bo + 2] - gMaxX).abs() > tol ||
          (bounds[bo + 3] - gMaxY).abs() > tol) {
        continue;
      }
      final lpTerm = lambda * set.logProb[t];
      final thresh = top.threshold;
      final tcx = set.centroidX[t], tcy = set.centroidY[t];
      final td = set.diag[t];
      final invTd = 1.0 / td;
      final base = t * kGesturePoints * 2;
      var locSum = 0.0, shapeSum = 0.0;
      var pruned = false;
      for (var i = 0; i < kGesturePoints; i++) {
        final tx = pts[base + i * 2] * invQ;
        final ty = pts[base + i * 2 + 1] * invQ;
        final dx = _rx[i] - tx, dy = _ry[i] - ty;
        locSum += _weights[i] * math.sqrt(dx * dx + dy * dy);
        final sx = (tx - tcx) * invTd - _gnx[i];
        final sy = (ty - tcy) * invTd - _gny[i];
        shapeSum += math.sqrt(sx * sx + sy * sy);
        if (i == checkA || i == checkB) {
          // The final mean location can only be >= partial/64.
          final lm = locSum * invKw;
          if (locSum > maxLocSum || lpTerm - lm * lm * invSigL2 < thresh) {
            pruned = true;
            break;
          }
        }
      }
      if (pruned) continue;
      final loc = locSum * invKw;
      if (loc > tuning.maxMeanLocation) continue;
      final shape = shapeSum / kGesturePoints * td * invKw;
      // The finger lands on the first and lifts on the last key precisely: score both ends on their own.
      final e0x = (_rx[0] - pts[base] * invQ) * invKw, e0y = (_ry[0] - pts[base + 1] * invQ) * invKw;
      final last = base + (kGesturePoints - 1) * 2;
      final e1x = (_rx[kGesturePoints - 1] - pts[last] * invQ) * invKw;
      final e1y = (_ry[kGesturePoints - 1] - pts[last + 1] * invQ) * invKw;
      final endTerm = (e0x * e0x + e0y * e0y + e1x * e1x + e1y * e1y) * invSigE2;
      final geo = -(loc * loc * invSigL2 + shape * shape * invSigS2 + endTerm);
      final score = geo + lpTerm;
      if (score > top.threshold) {
        top.offer(set.words[t], set.language[t], geo, set.logProb[t], set.learned, score);
      }
    }
  }
}

/// Fixed-size best-first list with de-duplication by word text.
class _TopK {
  _TopK(this.k);

  final int k;
  final List<RawCandidate> _items = [];
  final List<double> _scores = [];

  /// Score a new candidate has to beat to enter the list.
  double get threshold => _items.length < k ? double.negativeInfinity : _scores.last;

  void offer(String word, int language, double geo, double logProb, bool learned, double score) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].word == word) {
        if (score <= _scores[i]) return;
        _items.removeAt(i);
        _scores.removeAt(i);
        break;
      }
    }
    var at = _items.length;
    while (at > 0 && _scores[at - 1] < score) {
      at--;
    }
    _items.insert(at, RawCandidate(word, language, geo, logProb, learned));
    _scores.insert(at, score);
    if (_items.length > k) {
      _items.removeLast();
      _scores.removeLast();
    }
  }

  List<RawCandidate> results() => List.of(_items);
}

/// Per-point weights of the location channel (sum to 1), heavier at both ends.
Float64List _pointWeights(double endWeight) {
  final w = Float64List(kGesturePoints);
  var sum = 0.0;
  for (var i = 0; i < kGesturePoints; i++) {
    final fromEnd = math.min(i, kGesturePoints - 1 - i);
    w[i] = 1 + endWeight * math.exp(-fromEnd / 6);
    sum += w[i];
  }
  for (var i = 0; i < kGesturePoints; i++) {
    w[i] /= sum;
  }
  return w;
}
