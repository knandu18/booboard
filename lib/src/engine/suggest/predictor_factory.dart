// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 1-B (text engine). Builds the tap-typing predictor.
import '../../core/secure_blob_store.dart';
import '../../packs/pack_repository.dart';
import '../contracts.dart';
import 'text_predictor.dart';

TextPredictor createTextPredictor({
  required PackRepository packs,
  required LexiconSource lexicons,
  required SecureBlobStore store,
}) => BooBoardTextPredictor(lexicons: lexicons, store: store);
