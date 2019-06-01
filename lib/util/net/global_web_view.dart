import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:ln_reader/util/net/net_reader.dart';
import 'package:ln_reader/util/observable.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalWebView {
  static final cookieCache =
      ObservableValue.fromMap<String, Map<String, String>>({});

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
        print('fetching cloudflare cookies..');
        return _fetchCloudflareCookies(url).then((cfCookies) {
          // Update cookie cache
          if (useCookieCache) {
            final Map<String, String> mergedCookies = {};
            mergedCookies.addAll(cookies);
            mergedCookies.addAll(cfCookies);
            cookieCache.val[host] = mergedCookies;
          }

          // Re-call with cloudflare cookies
          return readPage(
            url,
            cookies: cfCookies,
            useCookieCache: useCookieCache,
          );
        });
      } else {
        // There is no issue, return the content
        return res.body;
      }
    });
  }

  static Future<Map<String, String>> _fetchCloudflareCookies(String url) {
    final cookieFetcher = Completer<Map<String, String>>();
    final browser = CustomBrowser();
    browser.cookieLoaders.add((cookies) {
      if (cookies.containsKey('__cfduid') &&
          cookies.containsKey('cf_clearance')) {
        print('__cfduid: ' + cookies['__cfduid']);
        print('cf_clearance: ' + cookies['cf_clearance']);
        if (!cookieFetcher.isCompleted) {
          cookieFetcher.complete({
            '__cfduid': cookies['__cfduid'],
            'cf_clearance': cookies['cf_clearance'],
          });
          browser.webViewController.stopLoading();
          browser.close();
        }
      }
    });

    browser.open(url: url, options: {
      'hidden': true,
      'transparentBackground': true,
      'clearCache': true,
      'userAgent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36',
    });

    return cookieFetcher.future;
  }
}

typedef CookieLoader = Function(Map<String, String> cookies);

class CustomBrowser extends InAppBrowser {
  final List<CookieLoader> cookieLoaders = [];
  String currentLoad;

  _loadCookies(String url) {
    CookieManager.getCookies(url).then((cookies) {
      Map<String, String> retVal = {};
      cookies.forEach((cookieMap) {
        retVal[cookieMap['name']] = cookieMap['value'];
      });
      cookieLoaders.forEach((loader) => loader(retVal));
    });
  }

  @override
  void onLoadStart(String url) {
    super.onLoadStart(url);
    _loadCookies(url);
    currentLoad = url;
  }

  @override
  void onLoadStop(String url) {
    super.onLoadStop(url);
    _loadCookies(url);
  }
}
