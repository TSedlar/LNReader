import 'dart:math';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' hide Text;

typedef ElementMapper = Widget Function(
  Element, {
  ThemeData theme,
  Map<String, dynamic> options,
});

class HtmlRenderer {
  static final _sentenceSplitter =
      RegExp('((([A-Za-z0-9.?!]+(((?<!Mrs?)\\.)|\\?|\\!) )|("([^"]+)")))');

  static const double defaultElementSpacing = 0.0;
  static const defaultLineSpacing = 1.1;

  static final ElementMapper defaultMapper = (element, {theme, options}) {
    switch (element.localName) {
      case 'p':
        {
          final children = <Widget>[];
          element.nodes.forEach((node) {
            String txt = node.text;
            if (txt != null && txt.isNotEmpty) {
              if (_isNumeric(txt)) {
                txt = '\n';
              }
              children.add(Text(txt, style: theme.textTheme.body1));
            }
          });
          return Column(
            children: children,
            crossAxisAlignment: CrossAxisAlignment.start,
          );
          // String txt = element.text;
          // if (txt != null && txt.trim().isNotEmpty) {
          //   return Text(
          //     _formatText(txt),
          //     style: theme.textTheme.body1.copyWith(
          //       height: options['line_spacing'] ?? defaultLineSpacing,
          //     ),
          //   );
          // }
        }
    }
    return null;
  };

  static String _formatText(String content) {
    return content.splitMapJoin(
      _sentenceSplitter,
      onMatch: (m) {
        String matched = m.group(0).trimRight();
        if (matched.endsWith('"')) {
          final spaceCount = matched.split(' ').length;
          return spaceCount > 2 ? '\n$matched\n' : '$matched ';
        } else {
          return '$matched\n';
        }
      },
      onNonMatch: (s) => s.trimLeft(),
    );
  }

  static bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  static void _visitRecursive(Element element, Function(Element) callback) {
    callback(element);
    element.children.forEach((e) => _visitRecursive(e, callback));
  }

  static List<Widget> createChildren(
    String html, {
    ThemeData theme,
    ElementMapper mapper,
    Map<String, dynamic> options = const {
      'element_spacing': defaultElementSpacing,
      'line_spacing': defaultLineSpacing,
    },
  }) {
    // Set unset defaults
    if (mapper == null) {
      mapper = defaultMapper;
    }

    if (theme == null) {
      theme = ThemeData.dark();
    }

    final children = <Widget>[];
    Document document;

    try {
      document = parse(html);
    } catch (_) {
      print('Failed to parse HTML');
      return children;
    }

    document.body.children.forEach((element) {
      _visitRecursive(element, (e) {
        children.add(mapper(e, theme: theme, options: options));
      });
    });

    return children
        .where((child) => child != null)
        .toList()
        .map((w) => Padding(
              padding: EdgeInsets.only(
                bottom: options['element_spacing'] ?? defaultElementSpacing,
              ),
              child: w,
            ))
        .toList();
  }
}
