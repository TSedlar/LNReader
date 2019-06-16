import 'package:flutter/material.dart' hide Element;
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' hide Text;

typedef NodeMapper = dynamic Function(
  Node, {
  Map<String, dynamic> options,
});

typedef WidgetMapper = List<Widget> Function(
  List, {
  ThemeData theme,
  Map<String, dynamic> options,
});

class HtmlRenderOptions {
  static const lineSpacing = 'line_spacing';
  static const breaksBetween = 'breaks_between';
}

class HtmlRenderer {
  static const defaultLineSpacing = 1.1;
  static const defaultBreaksBetween = 2;
  static const _unrenderable = ['script'];

  static Element _lastParent;

  static final NodeMapper defaultNodeMapper = (node, {options}) {
    if (node.nodeType == 3) {
      // It's a text node
      // Filter out unrenderable nodes
      String localName = node.parent?.localName;
      if (localName != null &&
          localName.isNotEmpty &&
          !_unrenderable.contains(localName)) {
        // Add line spacings if node parents have changed
        String txt = node.text.trim();
        if (node.parent != _lastParent) {
          _lastParent = node.parent;
          txt =
              ''.padLeft(options[HtmlRenderOptions.breaksBetween], '\n') + txt;
        }
        return txt;
      }
    }
    return null;
  };

  static final WidgetMapper defaultWidgetMapper = (nodes, {theme, options}) {
    // Create array variables
    final children = <Widget>[];
    final segments = <String>[];
    final pages = <String>[];

    // The current segment that will be added to the array
    String currentSegment = '';

    // Index tracking for any changes needed to be done
    int idx = 0;
    int lastAddedIdx = 0;

    final lineBreakStr =
        ''.padLeft(options[HtmlRenderOptions.breaksBetween], '\n');

    // Combine all lines possible for less elements
    nodes.forEach((nodeText) {
      String txt = nodeText.toString();
      if (txt.isNotEmpty) {
        bool lineBreak = txt.startsWith('\n');
        txt = txt.trimLeft();
        if (lineBreak) {
          txt = (lineBreakStr + txt);
        }
        if (_isNumeric(txt)) {
          segments.add(txt);
          pages.add(txt);
        } else {
          // Check if current segment is valid and does not end with a trimmable char
          if (currentSegment != null &&
              currentSegment.isNotEmpty &&
              currentSegment.trimRight() == currentSegment) {
            currentSegment += ' ';
          }
          currentSegment += txt;
          if (currentSegment.endsWith('?') || // Sentences
              currentSegment.endsWith('.') ||
              currentSegment.endsWith('!') ||
              currentSegment.endsWith('"') || // Quotes
              currentSegment.endsWith("'") ||
              currentSegment.endsWith(']') || // Dialog
              currentSegment.endsWith(')')) {
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
          isPage ? 'Page $seg' : seg.trimLeft(),
          style: theme.textTheme.body1.copyWith(
            height:
                options[HtmlRenderOptions.lineSpacing] ?? defaultLineSpacing,
          ),
        );

        if (isPage) {
          child = Center(child: child);
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: options[HtmlRenderOptions.lineSpacing] * 4,
          ),
          child: child,
        );
      }),
    );

    return [
      Column(
        children: children,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
      ),
    ];
  };

  static bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  static void _visitRecursive(Node node, Function(Node) callback) {
    callback(node);
    node.nodes.forEach((n) => _visitRecursive(n, callback));
  }

  static List<Widget> createChildren(
    String html, {
    ThemeData theme,
    NodeMapper nodeMapper,
    WidgetMapper widgetMapper,
    Map<String, dynamic> options = const {
      HtmlRenderOptions.lineSpacing: defaultLineSpacing,
      HtmlRenderOptions.breaksBetween: defaultBreaksBetween,
    },
  }) {
    // Set unset defaults
    if (nodeMapper == null) {
      nodeMapper = defaultNodeMapper;
    }

    if (widgetMapper == null) {
      widgetMapper = defaultWidgetMapper;
    }

    if (theme == null) {
      theme = ThemeData.dark();
    }

    final mappings = <dynamic>[];
    Document document;

    try {
      document = parse(html);
    } catch (_) {
      print('Failed to parse HTML');
      return [];
    }

    document.body.nodes.forEach((node) {
      _visitRecursive(node, (n) {
        mappings.add(nodeMapper(n, options: options));
      });
    });

    final children = widgetMapper(
      mappings.where((child) => child != null).toList(),
      theme: theme,
      options: options,
    );

    return children.where((child) => child != null).toList();
  }
}
