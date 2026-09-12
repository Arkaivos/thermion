import 'package:crypto/crypto.dart';

/// Comprueba [zipBytes] (el contenido descargado con el nombre [zipFilename])
/// contra el SHA-256 publicado en [sha256FileContents] — el contenido de
/// `filament.sha256`, en formato `sha256sum` (una línea por artefacto:
/// `<sha256>  <nombre>`; líneas en blanco y comentarios `#` se ignoran).
///
/// Función pura (sin E/S) para que la parte que decide si un zip es de
/// confianza se pueda probar sin descargar nada.
///
/// Lanza [StateError] si [zipFilename] no tiene entrada en el fichero de
/// sumas (un hueco silencioso sería peor que ninguna verificación: no se
/// acepta) o si el SHA-256 calculado no coincide con el esperado. Si todo
/// va bien, devuelve el digest calculado (para dejarlo en el log).
String verifyFilamentZipSha256({
  required List<int> zipBytes,
  required String zipFilename,
  required String sha256FileContents,
}) {
  String? expected;
  for (final rawLine in sha256FileContents.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final firstSpace = line.indexOf(RegExp(r'\s'));
    if (firstSpace == -1) continue;

    final hash = line.substring(0, firstSpace);
    // sha256sum en modo binario antepone "*" al nombre; lo aceptamos igual.
    final name = line.substring(firstSpace).trim().replaceFirst(RegExp(r'^\*'), '');

    if (name == zipFilename) {
      expected = hash;
      break;
    }
  }

  if (expected == null) {
    throw StateError(
      'No hay entrada SHA-256 para "$zipFilename" en filament.sha256; '
      'se rechaza la descarga en lugar de aceptarla sin verificar. '
      'Añade una entrada (ver la cabecera de filament.sha256) y reintenta.',
    );
  }

  final actual = sha256.convert(zipBytes).toString();
  if (actual != expected) {
    throw StateError(
      'El SHA-256 de "$zipFilename" no coincide: esperado $expected, '
      'obtenido $actual. El fichero descargado puede estar corrupto o el '
      'artefacto de la release puede haber cambiado; se rechaza.',
    );
  }

  return actual;
}
