import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:ln_reader/util/string_normalizer.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:url_launcher/url_launcher.dart';
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
        // Handle using+caching cloudflare cookies
        Loader.text.val = 'Fetching page cookies...';
        return _readCloudflarePage(url, cookies, useCookieCache);
      } else {
        // There is no issue, return the content
        return res.body;
      }
    });
  }

  static bool _launched = false;

  // Handles cloudflare challenge through a webview
  static Future<String> _readCloudflarePage(
    String url,
    Map<String, String> baseCookies,
    bool useCookieCache,
  ) {
    Loader.text.val = 'Started cookie grabbing...';

    // The key used in the cookie cache
    final host = Uri.parse(url).host;

    // Use this as the future to return
    final sourceCompleter = Completer<String>();

    // subscribable cookie listener
    final cookieSub = StreamController<Map>.broadcast();

    // Cleanup from hot reload
    if (!_launched) {
      FlutterWebviewPlugin()
        ..close()
        ..dispose();
    }

    // Get the singleton webview
    final plugin = FlutterWebviewPlugin();

    // Setup listener variables
    bool startedLoad = false;
    bool processingSource = false;

    plugin.onStateChanged.listen((state) async {
      Loader.text.val = 'Ensuring state change on URL';
      if (state.url == Uri.encodeFull(url) && !cookieSub.isClosed) {
        if (state.type == WebViewState.startLoad) {
          Loader.text.val = 'Started web load';
          if (!cookieSub.isClosed) {
            startedLoad = true;
            Loader.text.val = 'Retrieving cookies...';
            final cookies = await _platform.invokeMapMethod<String, String>(
              'getCookies',
              url,
            );
            Loader.text.val = 'Retrieved cookies';
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
          Loader.text.val = 'Found source part via webview';
          final source = StringNormalizer.normalize(
            await plugin.evalJavascript('document.body.innerHTML'),
          );
          if (source.isNotEmpty) {
            if (!_matchesCloudflare(source)) {
              if (!sourceCompleter.isCompleted) {
                Loader.text.val = 'Source grabbed!';
                cookieSub.close();
                sourceCompleter.complete(source);
                // keep things lightweight as this is in the background.
                plugin.reloadUrl('about:blank');
              }
            } else {
              Loader.text.val = 'Source matched loading page...';
            }
          }
          processingSource = false;
        }
      }
    });

    final launchCompleter = Completer();

    if (!_launched) {
      _launched = true;
      // Launch to about:blank as it's lightweight
      plugin
          .launch(
            'about:blank',
            withJavascript: true,
            hidden: true,
          )
          .then((_) => launchCompleter.complete());
    } else {
      launchCompleter.complete();
    }

    launchCompleter.future.then((_) => plugin.reloadUrl(url));

    cookieSub.stream.listen((cookies) {
      if (cookies != null &&
          cookies.containsKey('__cfduid') &&
          cookies.containsKey('cf_clearance')) {
        cookieSub.close();
        Loader.text.val = 'Cookies obtained';
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
          Loader.text.val = 'Read page source';
          // Only return the source if it's not another cloudflare challenge
          // which would mean the cookies are invalid
          if (res.body.isNotEmpty) {
            if (!_matchesCloudflare(res.body)) {
              if (!sourceCompleter.isCompleted) {
                Loader.text.val = 'Found source via NetReader';
                // keep things lightweight as this is in the background.
                plugin.reloadUrl('about:blank');
                sourceCompleter.complete(StringNormalizer.normalize(res.body));
              }
            } else {
              Loader.text.val = 'Cookies invalid \n Waiting for webview source';
            }
          }
        });
      }
    });

    return sourceCompleter.future.catchError((err) {
      // keep things lightweight as this is in the background.
      plugin.reloadUrl('about:blank');
    });
  }
}
