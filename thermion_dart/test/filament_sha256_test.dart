import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:thermion_dart/src/download/filament_sha256.dart';

void main() {
  group('verifyFilamentZipSha256', () {
    final bytes = utf8.encode('contenido de prueba del zip');
    final digest = sha256.convert(bytes).toString();

    test('acepta un zip cuyo hash coincide con la entrada del fichero', () {
      final sums = '# comentario\n$digest  filament-v1.69.1-android-release.zip\n';

      final result = verifyFilamentZipSha256(
        zipBytes: bytes,
        zipFilename: 'filament-v1.69.1-android-release.zip',
        sha256FileContents: sums,
      );

      expect(result, equals(digest));
    });

    test('lanza si el hash calculado no coincide con el esperado', () {
      final wrongDigest = sha256.convert(utf8.encode('otra cosa')).toString();
      final sums = '$wrongDigest  filament-v1.69.1-android-release.zip\n';

      expect(
        () => verifyFilamentZipSha256(
          zipBytes: bytes,
          zipFilename: 'filament-v1.69.1-android-release.zip',
          sha256FileContents: sums,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('lanza si el fichero de sumas no tiene entrada para el zip', () {
      final sums = '$digest  filament-v1.69.1-windows-release.zip\n';

      expect(
        () => verifyFilamentZipSha256(
          zipBytes: bytes,
          zipFilename: 'filament-v1.69.1-android-release.zip',
          sha256FileContents: sums,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
