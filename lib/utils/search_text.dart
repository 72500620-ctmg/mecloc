/// Normalização compartilhada por nomes, categorias e endereços.
String normalizeSearchText(String value) {
  const accents = {
    'a': 'áàâãä',
    'e': 'éèêë',
    'i': 'íìîï',
    'o': 'óòôõö',
    'u': 'úùûü',
    'c': 'ç',
  };
  var result = value.toLowerCase();
  for (final entry in accents.entries) {
    result = result.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  return result
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
