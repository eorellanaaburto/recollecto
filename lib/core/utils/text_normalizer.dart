class TextNormalizer {
  static String normalize(String value) {
    var text = value.trim().toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
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
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };

    replacements.forEach((key, replacement) {
      text = text.replaceAll(key, replacement);
    });

    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }
}
