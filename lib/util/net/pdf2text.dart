import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:interactive_webview/interactive_webview.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';

class Pdf2Text {
  // pdf2text disk directory
  static Directory get dir => Directory(globals.appDir.val.path + '/pd2text/');

  // Files within the disk directory
  static File get indexFile => File(dir.path + 'index.html');

  static File get pdfJsFile => File(dir.path + 'pdf.js');

  static File get pdfJsWorkerFile => File(dir.path + 'pdf.worker.js');

  // Asset paths
  static const indexAsset = 'assets/html_serve/pdf2text/index.html';
  static const pdfJsAsset = 'assets/html_serve/pdf2text/pdf.js';
  static const pdfJsWorkerAsset = 'assets/html_serve/pdf2text/pdf.worker.js';
  static const converterAsset = 'assets/html_serve/pdf2text/converter.js';

  // Asset mappings
  static Map<String, File> get assets => {
        indexAsset: indexFile,
        pdfJsAsset: pdfJsFile,
        pdfJsWorkerAsset: pdfJsWorkerFile,
      };

  static setup() async {
    dir.createSync(recursive: true);

    for (final assetKey in assets.keys) {
      final fileTarget = assets[assetKey];
      if (!fileTarget.existsSync()) {
        print('extracting $assetKey...');
        final bytes = await rootBundle.load(assetKey);
        await fileTarget.writeAsBytes(bytes.buffer.asUint8List());
        print('extracted to ${fileTarget.path}');
      }
    }

    print('Pdf2Text#setup complete');

    return true;
  }

  static Future<String> convert(
    LNPreview preview,
    LNChapter chapter,
  ) async {
    // Create the path to the locally downloaded pdf
    final pdfPath = preview.chapterDir.path + '/${chapter.index}.pdf';

    // Create the completer for when source is retrieved
    final sourceCompleter = Completer<String>();

    // Setup the webview
    final view = InteractiveWebView();

    // Setup the source receiver
    final msgReceiver = view.didReceiveMessage.listen((message) async {
      print(message.data['source']);
      sourceCompleter.complete(message.data['source']);
    });

    // Launch the converter
    await _launchConverter(view, pdfPath);

    // Wait for the source to be retrieved
    // Note: should this be timed out..? it should never not work..
    final source = await sourceCompleter.future;

    view.loadUrl('about:blank');

    Loader.text.val = 'Converted!';
    print('converted!');

    // Unsubscribe
    msgReceiver.cancel();

    return source;
  }

  static Future _launchConverter(view, pdfPath) async {
    // Extract html assets to disk for file:// URI
    await setup();

    // Setup the completer for page load finish
    final pageCompleter = Completer();

    // Listen for page finish event
    final stateChanger = view.stateChanged.listen((state) {
      if (state.type == WebViewState.didFinish) {
        Loader.text.val = 'Finished loading converter';
        print('Finished loading page...');
        pageCompleter.complete();
      }
    });

    // Load the index file
    view.loadUrl('file://' + indexFile.path);

    // Wait for page load to finish
    await pageCompleter.future;

    // Unsubscribe
    stateChanger.cancel();

    Loader.text.val = 'Loading PDF...';
    print('loading pdf...');

    // Get converter file source
    final converterSrc = await rootBundle.loadString(converterAsset);

    // Read pdf data from disk
    final pdfData = await File(pdfPath).readAsBytes();
    final pdfSrc = base64.encode(pdfData);

    Loader.text.val = 'Converting PDF...';
    print('converting pdf...');

    // Start conversion
    view.evalJavascript('''
      window['b64'] = "$pdfSrc";
      $converterSrc
    ''');

    return view;
  }
}
