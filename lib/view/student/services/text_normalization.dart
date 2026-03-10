// Servicio simple para normalizar cadenas (quitar acentos/diacríticos)
String normalize(String s) {
  var str = s.toLowerCase();
  const accents = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c'
  };
  accents.forEach((k, v) {
    str = str.replaceAll(k, v);
  });
  str = str.replaceAll(RegExp(r"[^a-z0-9\s]"), '');
  return str;
}
