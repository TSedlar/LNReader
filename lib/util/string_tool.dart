class StringTool {

  static bool endsWithR(String str, Pattern pattern) {
    var idx = str.lastIndexOf(pattern);
    if (idx >= 0) {
      str = str.substring(idx);
      str = str.replaceFirst(pattern, '');
      return str.isEmpty;
    }
    return false;
  }

  static String properFormat(String str) {
    str = str.toLowerCase();
    return str.substring(0, 1).toUpperCase() + str.substring(1);
  }

  static String normalize(String str, [bool removeLineBreaks = false]) {
    // Early catch null input
    if (str == null) {
      return null;
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
    // Replace control characters with a space
    str = String.fromCharCodes(str.runes.map((r) => r < 32 ? 32 : r).toList());
    // Return the string as trimmed
    return str.trim();
  }
}
