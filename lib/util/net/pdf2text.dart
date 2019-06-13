import 'dart:async';

import 'package:interactive_webview/interactive_webview.dart';
import 'package:jaguar/jaguar.dart';
import 'package:jaguar_flutter_asset/jaguar_flutter_asset.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';

class Pdf2Text {
  static Future<String> convert(
    LNPreview preview,
    LNChapter chapter, {
    int port = 8080,
  }) async {
    Loader.text.val = 'Creating server..';
    final server = Jaguar(port: port);

    server.addRoute(serveFlutterAssets());
    server.staticFiles('app/*', globals.appDir.val.path);
    server.serve();

    // Wait for server to spin up
    await Future.delayed(Duration(seconds: 2));

    Loader.text.val = 'Created server!';

    final pdfPath =
        '/app/${preview.source.id}/${preview.name}/chapters/${chapter.index}.pdf';
    final pdf2TextURL =
        'http://localhost:$port/html_serve/pdf2text/index.html?pdfPath=$pdfPath';

    final sourceCompleter = Completer<String>();

    final view = InteractiveWebView();

    final msgReceiver = view.didReceiveMessage.listen((message) async {
      view.loadUrl('about:blank');
      sourceCompleter.complete(message.data['source']);
    });

    view.loadUrl(pdf2TextURL);

    Loader.text.val = 'Converting PDF...';

    final source = await sourceCompleter.future;

    Loader.text.val = 'Converted!';

    msgReceiver.cancel();
    
    server.close().then((_) {
      print('Closed Jaguar server');
    });

    return source;
  }
}
