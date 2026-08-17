import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('canonical app icon exists and decodes as a 1024x1024 image', () {
    final iconFile = File('assets/brand/olcerim-app-icon.png');
    expect(iconFile.existsSync(), isTrue, reason: 'Canonical app icon must exist');

    final bytes = iconFile.readAsBytesSync();
    expect(bytes.isNotEmpty, isTrue);

    final decoded = img.decodeImage(bytes);
    expect(decoded, isNotNull, reason: 'Image must be decodable by flutter_launcher_icons decoder');
    expect(decoded!.width, equals(1024));
    expect(decoded.height, equals(1024));
  });
}
