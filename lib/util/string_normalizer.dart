class StringNormalizer {
  static String normalize(String str, [bool removeLineBreaks = false]) {
    // Null -> empty string
    if (str == null) {
      return '';
    }
    // Remove start/end quotes
    if (str.startsWith('"') && str.endsWith('"')) {
      str = str.substring(1, str.length - 1);
    }
    // Remove line breaks
    if (removeLineBreaks) {
      str = str.replaceAll(r'\n', '');
    }
    // Replace basic raw symbols
    str = str.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
    // Replace raw unicode symbols
    for (int i = 0; i <= 255; i++) {
      // Convert number to hex code (003c)
      String hexcode = i.toRadixString(16).padLeft(4, '0');
      // Replace with the real character
      String replacement = String.fromCharCode(int.parse('0x$hexcode'));
      // lower case unicode \u003c
      String lowUnicode = '\\u$hexcode';
      // upper case unicode \u003C
      String upUnicode = '\\u${hexcode.toUpperCase()}';
      str = str.replaceAll(lowUnicode, replacement).replaceAll(upUnicode, replacement);
    }
    // Remove control characters
    str = String.fromCharCodes(str.runes.toList().where((rune) => rune >= 32));
    // Return the string as trimmed
    return str.trim();
  }
}
