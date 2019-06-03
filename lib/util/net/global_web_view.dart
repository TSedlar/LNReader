import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:web_vuw/web_vuw.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/net/net_reader.dart';
import 'package:ln_reader/util/observable.dart';

typedef PageDataLoader = Function({
  InAppWebViewController controller,
  String actingURL,
  Map<String, String> cookies,
  String pageSource,
});

class GlobalWebView {
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
        print('fetching cloudflare cookies..');
        return _readCloudflarePage(url, cookies, useCookieCache);
      } else {
        // There is no issue, return the content
        return res.body;
      }
    });
  }

  static InAppWebViewController _backupController;

  // Handles cloudflare challenge through a webview
  static Future<String> _readCloudflarePage(
    String url,
    Map<String, String> baseCookies,
    bool useCookieCache,
  ) {
    print('started..');
    browser.val = new WebVuw(
        initialUrl: url,
        enableJavascript: true,
        javaScriptMode: JavaScriptMode.unrestricted,
        onWebViewCreated: (controller) {
          controller.onEvents().listen((e) {
            if (e['event'] == 'didFinish') {
              print('!!!!');
              controller.getCookies(url);
              print('@@@@');
              // controller.evaluateJavascript('document.body.innerHTML').then((src) {
              //   print(src);
              // });
            }
          });
        });

    // // Used to get the web controller
    // final ctr = Completer<InAppWebViewController>();

    // // The key used in the cookie cache
    // final host = Uri.parse(url).host;

    // // Use this as the future to return
    final sourceCompleter = Completer<String>();

    // // The callbacks to run upon each onLoadStart/onLoadStop
    // final List<PageDataLoader> dataLoaders = [
    //   ({controller, actingURL, cookies, pageSource}) {
    //     // Ensure source has not already been found
    //     // Also ensure we're working on the correct URL
    //     if (!sourceCompleter.isCompleted && actingURL == url) {
    //       // Check if cloudflare cookies are viable to read page source directly
    //       if (cookies != null &&
    //           cookies.containsKey('__cfduid') &&
    //           cookies.containsKey('cf_clearance')) {
    //         print('cookies were obtained');
    //         // Update the global cookie cache
    //         if (useCookieCache) {
    //           final Map<String, String> mergedCookies = {};
    //           mergedCookies.addAll(baseCookies);
    //           mergedCookies.addAll(cookies);
    //           cookieCache.val[host] = mergedCookies;
    //         }
    //         // Read the page source with retrieved cloudflare cookies
    //         NetReader.readPage(url, cookies: {
    //           '__cfduid': cookies['__cfduid'],
    //           'cf_clearance': cookies['cf_clearance'],
    //         }).then((res) {
    //           print('page was read...');
    //           // Only return the source if it's not another cloudflare challenge
    //           // which would mean the cookies are invalid
    //           if (!_matchesCloudflare(res.body)) {
    //             sourceCompleter.complete(res.body);
    //             print('Page source retrieved quickly');
    //             controller.stopLoading();
    //           }
    //         });
    //       }

    //       // Default to slow, albeit reliable and safe, webview page source
    //       if (pageSource != null) {
    //         print('Page source retrieved by webview');
    //         sourceCompleter.complete(pageSource);
    //         controller.stopLoading();
    //       }
    //     }
    //   }
    // ];

    // // Create new browser instance that updates the controller completer
    // if (!browser.seen) {
    //   browser.val = _makeView('about:blank', ctr, dataLoaders);
    // }

    // if (_backupController != null) {
    //   _backupController.loadUrl(url);
    // }

    // ctr.future.then((ctr) {
    //   if (!sourceCompleter.isCompleted) {
    //     ctr.loadUrl(url);
    //     // print('.......');
    //   }
    // });

    // Return when source is found or 15 second timeout
    return sourceCompleter.future.timeout(globals.timeoutLength);
  }

  static InAppWebView _makeView(
    String url,
    Completer<InAppWebViewController> ctrCompleter,
    List<PageDataLoader> dataLoaders,
  ) {
    bool matched = false;
    String currentURL;
    return InAppWebView(
      initialUrl: url,
      onWebViewCreated: (controller) {
        _backupController = controller;
        // Only one controller needs to be used..
        if (!ctrCompleter.isCompleted) {
          print('Initialized controller');
          ctrCompleter.complete(controller);
        }
      },
      onLoadStart: (controller, url) {
        if (!matched) {
          controller.isLoading().then((loading) {
            if (loading) {
              print('onLoadStart: $url');
              currentURL = url;
              _loadData(controller, dataLoaders, cookieURL: url);
            }
          });
        }
      },
      onLoadStop: (controller, url) {
        if (!matched) {
          controller.isLoading().then((loading) {
            if (loading) {
              print('onLoadStop: $url');
              controller
                  .injectScriptCode('document.body.innerHTML')
                  .then((source) {
                if (!_matchesCloudflare(source)) {
                  matched = true;
                  _loadData(controller, dataLoaders,
                      actingURL: url, source: source);
                } else {
                  print('cloudflare...');
                }
              });
            }
          });
        }
      },
      onProgressChanged: (controller, progress) {
        if (!matched) {
          controller.isLoading().then((loading) {
            if (loading) {
              controller.injectScriptCode('document.readyState').then((ready) {
                print('oPC @ $progress -> $ready, $currentURL');
                if (ready == 'interactive' || progress == 100) {
                  controller.injectScriptCode('document.body.innerHTML').then(
                    (source) {
                      if (!_matchesCloudflare(source)) {
                        matched = true;
                        _loadData(
                          controller,
                          dataLoaders,
                          actingURL: url,
                          source: source,
                        );
                      }
                    },
                  );
                }
              });
            }
          });
        }
      },
    );
  }

  // handle passing the data to all of the _dataLoaders
  static _loadData(
    InAppWebViewController controller,
    List<PageDataLoader> dataLoaders, {
    String actingURL,
    String source,
    String cookieURL,
  }) {
    if (source != null) {
      dataLoaders.toList().forEach(
            (loader) => loader(
                  controller: controller,
                  actingURL: actingURL,
                  pageSource: source,
                ),
          );
    }
    if (cookieURL != null) {
      CookieManager.getCookies(cookieURL).then((cookies) {
        Map<String, String> retVal = {};
        cookies.forEach((cookieMap) {
          retVal[cookieMap['name']] = cookieMap['value'];
        });
        dataLoaders.toList().forEach(
              (loader) => loader(
                    controller: controller,
                    actingURL: actingURL,
                    cookies: retVal,
                  ),
            );
      });
    }
  }
}

class GlobalWebViewWidget extends StatefulWidget {
  _GlobalWebViewWidget createState() => _GlobalWebViewWidget();
}

class _GlobalWebViewWidget extends State<GlobalWebViewWidget> {
  Widget view;

  @override
  void initState() {
    super.initState();
    GlobalWebView.browser.listen((updatedView) {
      if (mounted) {
        setState(() {
          view = updatedView;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return view != null ? view : Container();
  }
}
