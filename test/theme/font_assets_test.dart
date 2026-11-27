import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Google Sans Flex is bundled with its licence and declared in pubspec', () {
    final ttf = File('assets/fonts/GoogleSansFlex.ttf');
    expect(ttf.existsSync(), isTrue);
    expect(ttf.lengthSync(), greaterThan(1000000));
    // TrueType magic number.
    expect(ttf.openSync().readSync(4), [0x00, 0x01, 0x00, 0x00]);
    final ofl = File('assets/fonts/OFL.txt').readAsStringSync();
    expect(ofl, contains('SIL OPEN FONT LICENSE Version 1.1'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: GoogleSansFlex'));
    expect(pubspec, contains('asset: assets/fonts/GoogleSansFlex.ttf'));
  });

  test('the font file contains the wght and ROND axes', () {
    final bytes = File('assets/fonts/GoogleSansFlex.ttf').readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    final tables = data.getUint16(4);
    int? fvar;
    for (var i = 0; i < tables; i++) {
      final o = 12 + 16 * i;
      if (String.fromCharCodes(bytes.sublist(o, o + 4)) == 'fvar') fvar = data.getUint32(o + 8);
    }
    expect(fvar, isNotNull);
    final f = fvar!;
    final axisOffset = data.getUint16(f + 4);
    final count = data.getUint16(f + 8);
    final size = data.getUint16(f + 10);
    final tags = [
      for (var a = 0; a < count; a++)
        String.fromCharCodes(bytes.sublist(f + axisOffset + a * size, f + axisOffset + a * size + 4)),
    ];
    expect(tags, containsAll(['wght', 'ROND']));
  });
}
