// Asset check for the 3D mascot: assets/3d/monkey.glb must stay a valid
// glTF binary under 3 MB with the five clips the app expects.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const int maxBytes = 3 * 1024 * 1024;
const List<String> clips = <String>[
  'idle',
  'happy',
  'worried',
  'celebrating',
  'sleeping',
];

void main() {
  final File file = File('assets/3d/monkey.glb');

  test('monkey.glb exists and is under 3 MB', () {
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), lessThan(maxBytes));
  });

  test('monkey.glb is glTF 2.0 with the five named clips', () {
    final Uint8List bytes = file.readAsBytesSync();
    final ByteData header = ByteData.sublistView(bytes);
    expect(utf8.decode(bytes.sublist(0, 4)), 'glTF');
    expect(header.getUint32(4, Endian.little), 2);
    expect(header.getUint32(8, Endian.little), bytes.length);
    final int jsonLength = header.getUint32(12, Endian.little);
    expect(header.getUint32(16, Endian.little), 0x4E4F534A); // "JSON"
    final Map<String, dynamic> json = jsonDecode(
      utf8.decode(bytes.sublist(20, 20 + jsonLength)),
    ) as Map<String, dynamic>;
    expect((json['asset'] as Map<String, dynamic>)['version'], '2.0');
    final List<String> names = <String>[
      for (final dynamic a in json['animations'] as List<dynamic>)
        (a as Map<String, dynamic>)['name'] as String,
    ];
    expect(names, containsAll(clips));
  });
}
