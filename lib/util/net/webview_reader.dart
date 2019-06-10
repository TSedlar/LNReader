import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_reader/util/string_normalizer.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:interactive_webview/interactive_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebviewReader {
  static const _platform = const MethodChannel('ln_reader/native');

  // Launches the given URL in an external browser
  static launchExternal(BuildContext context, String url) =>
      canLaunch(url).then((available) {
        if (available) {
          launch(url);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text('Error'),
                  content: Text('Unable to launch in external browser'),
                ),
          );
        }
      });

  static Future<String> read(
    String url, {
    Duration timeout = const Duration(milliseconds: 12500),
  }) async {
    final start = DateTime.now();
    int timeoutMillis = timeout.inMilliseconds;

    final uri = Uri.parse(Uri.encodeFull(url.replaceAll(' ', '%20')));

    final view = InteractiveWebView();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final sourceCompleter = Completer<String>();

    Loader.extendedText.val = null;

    Loader.text.val = 'Fetching cookies...';

    final msgReceiver = view.didReceiveMessage.listen((message) async {
      if (!sourceCompleter.isCompleted) {
        final cookies = await _platform.invokeMapMethod<String, String>(
          'getCookies',
          url,
        );

        if (cookies.containsKey('__cfduid') &&
            cookies.containsKey('cf_clearance')) {
          prefs.setString(
            'cf_cookies',
            '__cfduid=${cookies['__cfduid']}; cf_clearance=${cookies['cf_clearance']};',
          );

          Loader.text.val = 'Found cookies!';
        }

        final data = message.data as Map;

        if (data.containsKey('source')) {
          final source = data['source'].toString();
          if (source.trim().isNotEmpty) {
            if (isCloudflare(source)) {
              // Since we have to load two pages, double the timeout.
              timeoutMillis *= 2;
              Loader.text.val = 'Waiting for cloudflare...';
              Loader.extendedText.val = 'Please wait for cloudflare...';
            } else {
              Loader.text.val = 'Source found!';
              if (!sourceCompleter.isCompleted) {
                sourceCompleter.complete(source);
              }
            }
          }
        } else if (data.containsKey('state')) {
          Loader.text.val = 'Page is ${data['state']}';
          if (data['state'] == 'interactive' || data['state'] == 'complete') {
            Loader.text.val = Loader.text.val + '!';
            await view.evalJavascript('''
              var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;
              nativeCommunicator.postMessage(JSON.stringify({ "source": document.body.innerHTML }));
            ''');
          } else {
            Loader.text.val = Loader.text.val + '...';
          }
        }
      }
    });

    final stateChanger = view.stateChanged.listen((state) async {
      print('state: ${state.type}');
      if (state.type == WebViewState.didStart) {
        Loader.text.val = 'Started page load...';
        Future.doWhile(() async {
          await Future.delayed(Duration(milliseconds: 100));
          view.evalJavascript('''
            var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;
            nativeCommunicator.postMessage(JSON.stringify({ "state": document.readyState }));
          ''');
          return !sourceCompleter.isCompleted;
        }).timeout(timeout, onTimeout: () {});
      } else if (state.type == WebViewState.didFinish) {
        Loader.text.val = 'Finished load!';
        await view.evalJavascript('''
          var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;
          nativeCommunicator.postMessage(JSON.stringify({ "source": document.body.innerHTML }));
        ''');
        view.loadUrl('about:blank');
      }
    });

    view.setOptions(
      restrictedSchemes: [uri.host],
    );

    final headers = {
      'method': 'GET',
      'scheme': 'https',
      'authority': uri.host,
      'path': '/',
      'cache-control': 'max-age=0',
      'upgrade-insecure-requests': '1',
      'dnt': '1',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36',
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
      'referer': uri.origin,
      'accept-encoding': 'gzip, deflate',
      'accept-language': 'en-US,en;q=0.9',
    };

    if (prefs.containsKey('cf_cookies')) {
      headers['cookie'] = prefs.getString('cf_cookies');
    }

    view.loadUrl(uri.toString(), headers: headers);

    String pageSource;

    try {
      sourceCompleter.future.then((src) => pageSource = src);
      final timeoutStart = DateTime.now();
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 100));

        final difference =
            DateTime.now().difference(timeoutStart).inMilliseconds;

        if (difference >= timeoutMillis) {
          Loader.text.val = 'Timed out...';
          throw TimeoutException(
            'Network request timed out: ${difference}ms',
          );
        }
        return difference < timeoutMillis && !sourceCompleter.isCompleted;
      });
    } catch (err) {
      msgReceiver.cancel();
      stateChanger.cancel();
      view.loadUrl('about:blank');
      throw err;
    }

    Loader.text.val = null;

    final timeTaken = DateTime.now().difference(start).inMilliseconds;
    print('source retrieved in: ${timeTaken}ms');

    msgReceiver.cancel();
    stateChanger.cancel();
    view.loadUrl('about:blank');

    return StringNormalizer.normalize(pageSource);
  }

  static bool isCloudflare(String source) {
    return source.contains('cf-im-under-attack') ||
        source.contains('jschl_vc') ||
        source.contains('chk_jschl');
  }

  static void clearCookies() {
    _platform.invokeMethod('clearCookies');
  }
}
