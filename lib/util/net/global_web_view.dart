import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:ln_reader/util/string_normalizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/net/net_reader.dart';
import 'package:ln_reader/util/observable.dart';

class GlobalWebView {
  static const _platform = const MethodChannel('ln_reader/native');

  // The default background browser singleton used for
  // reading page sources as a last resort.
  static final browser = ObservableValue<Widget>();

  static final cookieCache =
      ObservableValue.fromMap<String, Map<String, String>>({});

  // Checks that the page source does not match cloudflare challenge
  static bool _matchesCloudflare(String source) {
    return source.contains('Just a moment...') || source.contains('jschl_vc');
  }

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

  // Reads the given url's page source
  static Future<String> readPage(
    String url, {
    Map<String, String> cookies,
    bool useCookieCache = true,
  }) {
    // Get the url hostname
    final host = Uri.parse(url).host;

    // Initialize empty cookies
    if (cookies == null) {
      cookies = {};
    }

    // Populate cookies from cache if enabled
    if (useCookieCache) {
      if (cookieCache.val.containsKey(host)) {
        if (cookies == null) {
          cookies = {};
        }
        cookies.addAll(cookieCache.val[host]);
      }
    }

    // Read the page with cookies
    return NetReader.readPageInBackground(url, cookies: cookies).then((res) {
      if (res.headers != null &&
          'cloudflare' == res.headers['server'] &&
          'close' == res.headers['connection']) {
        print(res.body);
        // Handle using+caching cloudflare cookies
        print('fetching cloudflare cookies..');
        return _readCloudflarePage(url, cookies, useCookieCache);
      } else {
        // There is no issue, return the content
        return res.body;
      }
    });
  }

  // Handles cloudflare challenge through a webview
  static Future<String> _readCloudflarePage(
    String url,
    Map<String, String> baseCookies,
    bool useCookieCache,
  ) {
    print('started..');

    // The key used in the cookie cache
    final host = Uri.parse(url).host;

    // Use this as the future to return
    final sourceCompleter = Completer<String>();

    final cookieSub = StreamController<Map>.broadcast();

    // Ensure a clean plugin
    FlutterWebviewPlugin()
      ..stopLoading()
      ..cleanCookies()
      ..close()
      ..dispose();

    final plugin = FlutterWebviewPlugin();

    bool startedLoad = false;
    bool processingSource = false;

    plugin.onStateChanged.listen((state) async {
      if (state.url == url && !cookieSub.isClosed) {
        if (state.type == WebViewState.startLoad) {
          if (!cookieSub.isClosed) {
            startedLoad = true;
            print('retrieving cookies..');
            final cookies = await _platform.invokeMapMethod<String, String>(
              'getCookies',
              url,
            );
            print('retrieved cookies: ' + cookies.toString());
            cookieSub.add(cookies);
          }
        }
      }
    });

    plugin.onProgressChanged.listen((progress) async {
      if (startedLoad) {
        final state = StringNormalizer.normalize(
          await plugin.evalJavascript('document.readyState'),
        );
        if (!processingSource &&
            (state == 'interactive' || state == 'complete')) {
          processingSource = true;
          print('found source with webview');
          final source = StringNormalizer.normalize(
            await plugin.evalJavascript('document.body.innerHTML'),
          );
          if (!_matchesCloudflare(source)) {
            if (!sourceCompleter.isCompleted) {
              print('source is correct');
              cookieSub.close();
              sourceCompleter.complete(source);
              plugin.stopLoading();
              plugin.close();
              plugin.dispose();
            }
          } else {
            print('source matched cloudflare..');
          }
          processingSource = false;
        }
      }
    });

    plugin.launch(
      url,
      withJavascript: true,
      hidden: true,
    );

    cookieSub.stream.listen((cookies) {
      if (cookies != null &&
          cookies.containsKey('__cfduid') &&
          cookies.containsKey('cf_clearance')) {
        cookieSub.close();
        print('cookies were obtained');
        // Update the global cookie cache
        if (useCookieCache) {
          final Map<String, String> mergedCookies = {};
          mergedCookies.addAll(baseCookies);
          mergedCookies.addAll(cookies);
          cookieCache.val[host] = mergedCookies;
        }
        // Read the page source with retrieved cloudflare cookies
        NetReader.readPage(url, cookies: {
          '__cfduid': cookies['__cfduid'],
          'cf_clearance': cookies['cf_clearance'],
        }).then((res) {
          print('page was read...');
          // Only return the source if it's not another cloudflare challenge
          // which would mean the cookies are invalid
          if (!_matchesCloudflare(res.body)) {
            if (!sourceCompleter.isCompleted) {
              print('Page source retrieved quickly');
              plugin.stopLoading();
              plugin.close();
              plugin.dispose();
              sourceCompleter.complete(res.body);
            }
          } else {
            print('cookies did not work, waiting for webview#finishLoad');
          }
        });
      }
    });

    return sourceCompleter.future.timeout(globals.timeoutLength, onTimeout: () {
      print('timed out..');
      plugin.close();
      plugin.dispose();
      return null;
    });
  }
}
