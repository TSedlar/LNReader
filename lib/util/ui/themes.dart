class Themes {
  static final Map<String, String> deepBlue = {
    'navigation': '#12151b', // system navbar colors
    'background': '#1d222c', // reader color, appbar color
    'background_accent': '#161a21', // background for containers
    'foreground': '#b6b3a4', // main text color
    'foreground_accent': '#b6b3a4', // text color when bg is background_accent
    'headings': '#dad8cc', // should be darker than foreground
  };

  static final Map<String, String> darkMono = {
    'navigation': '#161616', // system navbar colors
    'background': '#222222', // reader color, appbar color
    'background_accent': '#303030', // background for containers
    'foreground': '#a9a9a9', // main text color
    'foreground_accent': '#a9a9a9', // text color when bg is background_accent
    'headings': '#f7f7f7', // should be darker than foreground
  };

  static final Map<String, String> paleNight = {
    'navigation': '#222738', // system navbar colors
    'background': '#282d3f', // reader color, appbar color
    'background_accent': '#23222d', // background for containers
    'foreground': '#6a7091', // main text color
    'foreground_accent': '#a0a6c6', // text color when bg is background_accent
    'headings': '#8b91b2', // should be darker than foreground
  };

  static final Map<String, String> paper = {
    'navigation': '#c3c0bf', // system navbar colors
    'background': '#dddbda', // reader color, appbar color
    'background_accent': '#d1cecd', // background for containers
    'foreground': '#2e2f31', // main text color
    'foreground_accent': '#2e2f31', // text color when bg is background_accent
    'headings': '#282929', // should be darker than foreground
  };

  static final Map<String, String> notepad = {
    'navigation': '#acae8b', // system navbar colors
    'background': '#c9cca2', // reader color, appbar color
    'background_accent': '#cecbc1', // background for containers
    'foreground': '#2e2f31', // main text color
    'foreground_accent': '#2e2f31', // text color when bg is background_accent
    'headings': '#282929', // should be darker than foreground
  };

  static final Map<String, String> materialBlue = {
    'navigation': '#1c8de8', // system navbar colors
    'background': '#2196f3', // reader color, appbar color
    'background_accent': '#dedcde', // background for containers
    'foreground': '#dedcde', // main text color
    'foreground_accent': '#1d2938', // text color when bg is background_accent
    'headings': '#ffffff', // should be darker than foreground
  };

  static final Map<String, Map<String, String>> listing = {
    'Deep Blue': deepBlue,
    'Dark Mono': darkMono,
    'Pale Night': paleNight,
    'Paper': paper,
    'Notepad': notepad,
    'Material Blue': materialBlue,
  };
}
