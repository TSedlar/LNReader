import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_reader/util/net/connection_status.dart';
import 'package:ln_reader/util/net/pdf2text.dart';
import 'package:ln_reader/util/net/webview_reader.dart';
import 'package:ln_reader/views/widget/swipeable_route.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/views/about_view.dart';
import 'package:ln_reader/views/settings_view.dart';
import 'package:ln_reader/views/entry_view.dart';
import 'package:ln_reader/views/home_view.dart';
import 'package:ln_reader/views/landing_view.dart';
import 'package:ln_reader/views/reader_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: unused_element
_emulateInitialRun() async {
  print('performing initial review cleanup');
  // Temporarily remove caching to see review performance
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // Clear cookies for the same reason above as well
  WebviewReader.clearCookies();

  // Remove saved data
  await globals.deleteFiles();

  // Remove pdf2text dir
  if (Pdf2Text.dir.existsSync()) {
    await Pdf2Text.dir.delete(recursive: true);
  }
}

void main() async {
  // Setup app directory
  globals.appDir.val = await getApplicationDocumentsDirectory();

  // Delete files to simulate iOS/Android first-run review
//  await _emulateInitialRun(); // comment out when building release

  // Start the watcher for global updates
  await globals.startWatcher();

  // Set navigation colors
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: HexColor(globals.theme.val['navigation']),
    systemNavigationBarColor: HexColor(globals.theme.val['navigation']),
  ));

  ConnectionStatus connection = ConnectionStatus.getInstance();

  connection.connectionChange.listen((online) {
    globals.offline.val = !online;
  });

  connection.initialize();

  // Start application
  runApp(MainApplication());
}

class MainApplication extends StatefulWidget {
  MainApplication({Key key}) : super(key: key);

  @override
  _MainApplication createState() => _MainApplication();
}

class _MainApplication extends State<MainApplication>
    with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Current lifecycle state: ' + state.toString());
    // Sync globals when app lifecycle changes (if they've already been read)
    if (globals.runningWatcher &&
        (state == AppLifecycleState.suspending ||
            state == AppLifecycleState.paused)) {
      print('Syncing data due to state change');
      globals.writeToFile();
    }
  }

  @override
  void initState() {
    // Initialize super state
    super.initState();

    // Setup lifecycle watcher
    WidgetsBinding.instance.addObserver(this);

    // Change nav colors in realtime
    globals.theme.listen((theme) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: HexColor(theme['navigation']),
        systemNavigationBarColor: HexColor(theme['navigation']),
      ));
    });

    // Bind theme/load var for realtime changes
    globals.theme.bind(this);
  }

  @override
  void dispose() {
    // Remove lifecycle watcher
    WidgetsBinding.instance.removeObserver(this);

    // Dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = globals.createColorTheme();

    // Create the application
    return MaterialApp(
      title: 'LNReader',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        bool transition = true;
        Widget displayWidget;
        bool fullscreen = false;
        if (settings.name == '/') {
          final args = settings.arguments as Map;
          transition = false;
          displayWidget = LandingView(
            forceHome: args != null && args.isNotEmpty && args['force_home'],
          );
        } else if (settings.name == '/settings') {
          displayWidget = SettingsView();
        } else if (settings.name == '/about') {
          displayWidget = AboutView();
        } else if (settings.name == '/home') {
          // Handle HomeView
          final HomeArgs args = settings.arguments;
          displayWidget = HomeView(
            source: args.source,
            html: args.html,
            isSearch: args.isSearch,
          );
        } else if (settings.name == '/entry') {
          // Handle EntryView
          final EntryArgs args = settings.arguments;
          displayWidget = EntryView(
            preview: args.preview,
            html: args.html,
            usingCache: args.usingCache,
          );
        } else if (settings.name == '/reader') {
          // Handle ReaderView
          final ReaderArgs args = settings.arguments;
          displayWidget = ReaderView(
            preview: args.preview,
            chapter: args.chapter,
            html: args.html,
          );
          fullscreen = true;
        }

        if (fullscreen) {
          SystemChrome.setEnabledSystemUIOverlays([]);
        } else {
          SystemChrome.setEnabledSystemUIOverlays([
            SystemUiOverlay.top,
            SystemUiOverlay.bottom,
          ]);
        }

        if (transition) {
          return SwipeableRoute(
            builder: (ctx) => displayWidget,
          );
        } else {
          return MaterialPageRoute(
            builder: (ctx) => displayWidget,
          );
        }
      },
    );
  }
}
