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

  static const double defaultElementSpacing = 5.0;
  static const defaultLineSpacing = 1.1;

  static final ElementMapper defaultMapper = (element, {theme, options}) {
    switch (element.localName) {
      case 'p':
        {
          // Create array variables
          final children = <Widget>[];
          final segments = <String>[];
          final pages = <String>[];

          // The current segment that will be added to the array
          String currentSegment = '';

          // Index tracking for any changes needed to be done
          int idx = 0;
          int lastAddedIdx = 0;

          // Combine all lines possible for less elements
          element.nodes.forEach((node) {
            String txt = node.text.trim();
            if (txt != null && txt.isNotEmpty) {
              if (_isNumeric(txt)) {
                segments.add(txt);
                pages.add(txt);
              } else {
                if (currentSegment != null && currentSegment.isNotEmpty) {
                  currentSegment += ' ';
                }
                currentSegment += txt;
                if (currentSegment.endsWith('?') ||
                    currentSegment.endsWith('.') ||
                    currentSegment.endsWith('!') ||
                    currentSegment.endsWith('"') ||
                    currentSegment.endsWith("'")) {
                  segments.add(currentSegment);
                  currentSegment = '';
                  lastAddedIdx = idx;
                }
              }
            }
            idx++;
          });

          // Ensure last remaining text is added
          if (lastAddedIdx != idx && currentSegment.trim().isNotEmpty) {
            segments.add(currentSegment);
          }

          // Create elements from segments
          children.addAll(
            segments.map((seg) {
              bool isPage = pages.contains(seg);
              
              Widget child = Text(
                isPage ? 'Page $seg' : seg,
                style: theme.textTheme.body1.copyWith(
                  height: options['line_spacing'] ?? defaultLineSpacing,
                ),
              );

              if (isPage) {
                child = Center(child: child);
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: options['element_spacing'] ?? defaultElementSpacing,
                ),
                child: child,
              );
            }),
          );

          return Column(
            children: children,
            crossAxisAlignment: CrossAxisAlignment.start,
          );
        }
    }
    return null;
  };

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

    return children.where((child) => child != null).toList();
  }
}
