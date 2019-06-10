import 'package:flutter/foundation.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';

class LNIsolate {
  // START LNSource#parsePreview
  static Future<Map<String, List<LNPreview>>> parsePreviews(
    LNSource source,
    String html,
  ) {
    Loader.text.val = 'Parsing previews...';
    return compute(_parsePreviews, {
      'source': source.id,
      'html': html,
    });
  }

  static Map<String, List<LNPreview>> _parsePreviews(Map args) {
    return globals.sources[args['source']].parsePreviews(args['html']);
  }

  // START LNSource#parseSearchPreviews
  static Future<List<LNPreview>> parseSearchPreviews(
    LNSource source,
    String html,
  ) {
    Loader.text.val = 'Parsing search previews...';
    return compute(_parseSearchPreviews, {
      'source': source.id,
      'html': html,
    });
  }

  static List<LNPreview> _parseSearchPreviews(Map args) {
    return globals.sources[args['source']].parseSearchPreviews(args['html']);
  }

  // START LNSource#makeReaderContent
  static Future<String> makeReaderContent(
    LNSource source,
    String html,
  ) {
    Loader.text.val = 'Making reader content...';
    return compute(_makeReaderContent, {
      'source': source.id,
      'html': html,
    });
  }

  static String _makeReaderContent(Map args) {
    return globals.sources[args['source']].makeReaderContent(args['html']);
  }

  // START LNSource#parseEntry
  static Future<LNEntry> parseEntry(
    LNSource source,
    String html,
  ) {
    Loader.text.val = 'Parsing entry...';
    return compute(_parseEntry, {
      'source': source.id,
      'html': html,
    });
  }

  static LNEntry _parseEntry(Map args) {
    return globals.sources[args['source']].parseEntry(
      globals.sources[args['source']],
      args['html'],
    );
  }
}
