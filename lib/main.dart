import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slide_container/slide_container.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/net/global_web_view.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/views/about_view.dart';
import 'package:ln_reader/views/settings_view.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/entry_view.dart';
import 'package:ln_reader/views/home_view.dart';
import 'package:ln_reader/views/landing_view.dart';
import 'package:ln_reader/views/reader_view.dart';

void main() async {
  // Start the watcher for global updates
  await globals.startWatcher();

  // Set navigation colors
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: HexColor(globals.theme.val['navigation']),
    systemNavigationBarColor: HexColor(globals.theme.val['navigation']),
  ));

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
  int _dCounter = 0;

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
    GlobalWebView.browser.bind(this);
    globals.theme.bind(this);
    globals.loading.bind(this);
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
        Widget displayWidget;
        bool fullscreen = false;
        if (settings.name == '/') {
          displayWidget = LandingView();
        } else if (settings.name == '/settings') {
          displayWidget = SettingsView();
        } else if (settings.name == '/about') {
          displayWidget = AboutView();
        } else if (settings.name == '/home') {
          // Handle HomeView
          globals.loading.val = false;
          final HomeArgs args = settings.arguments;
          displayWidget = HomeView(
            previews: args.previews,
            searchPreviews: args.searchPreviews,
          );
        } else if (settings.name == '/entry') {
          // Handle EntryView
          globals.loading.val = false;
          final EntryArgs args = settings.arguments;
          displayWidget = EntryView(
            preview: args.preview,
            entry: args.entry,
          );
        } else if (settings.name == '/reader') {
          // Handle ReaderView
          globals.loading.val = false;
          final ReaderArgs args = settings.arguments;
          displayWidget =
              ReaderView(chapter: args.chapter, markdown: args.markdown);
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

        // Show loader while loading variable is set
        displayWidget = ModalProgressHUD(
          opacity: 1.0,
          color: theme.accentColor,
          progressIndicator: Loader.makeIndicator(),
          inAsyncCall: globals.loading.val,
          child: displayWidget,
        );

        // if (transition) {
        return CupertinoPageRoute(
          // maintainState: true,
          builder: (ctx) => displayWidget,
        );
        // } else {
        // return MaterialPageRoute(
        //   maintainState: true,
        //   builder: (ctx) => displayWidget,
        // );
        // }
      },
    );
  }
}
