import 'package:flutter/material.dart' hide Element;
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' hide Text;

import '../string_tool.dart';

typedef NodeMapper = dynamic Function(
  Node, {
  Map<String, dynamic> options,
});

typedef WidgetMapper = List<Widget> Function(
  List, {
  BuildContext context,
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
  static const _unrenderable = <String>['script', 'video', 'hr'];
  static const _headerTags = <String>['h1', 'h2', 'h3', 'h4', 'h5'];
  static final _containedTags = <String>['p']..addAll(_headerTags);
  static const _imgPrefix = 'handle_img:';

  static bool _lastAddedBreak = true;

  static final NodeMapper defaultNodeMapper = (node, {options}) {
    // 1 == element node
    // 3 == text node
    if (node.nodeType == 3) {
      // Get parent element name
      // Filter out unrenderable nodes
      String parentTag = node.parent?.localName;
      if (parentTag != null &&
          parentTag.isNotEmpty &&
          !_unrenderable.contains(parentTag)) {
        String txt = node.text.trim();
        // Only add if not empty
        if (!_isEmpty(txt)) {
          _lastAddedBreak = false;
          // Check if we need to show that this is a header
          if (_headerTags.contains(parentTag)) {
            txt = '\n\n' + txt + '\n';
          }
          return txt;
        }
      }
    } else if (node.nodeType == 1) {
      // Get the node's element name
      Element element;
      String tag;
      if (node.nodes.isNotEmpty) {
        element = node.nodes[0].parent;
        tag = element.localName;
      }
      if (node.attributes.containsKey('src') &&
          node.attributes.containsKey('alt')) {
        final url = node.attributes['src'];
        if (_verifyImg(url)) {
          return _imgPrefix + url;
        }
      }
      // Check if we should add a line break
      if (!_lastAddedBreak) {
        if (!_headerTags.contains(tag) &&
            _containedTags.contains(tag) &&
            !_isEmpty(node.text)) {
          _lastAddedBreak = true;
          return '\n';
        }
      }
    }
    return null;
  };

  static final WidgetMapper defaultWidgetMapper = (
    nodes, {
    context,
    theme,
    options,
  }) {
    // Create array variables
    final children = <Widget>[];
    final pages = <String>[];
    
    // Fetch segments
    final segments = parseSegments(nodes, pages: pages);

    // Create elements from segments
    children.addAll(
      segments.map((seg) {
        bool shouldCenter = false;
        Widget child;

        if (seg.contains(_imgPrefix)) {
          final imgURL = seg.split(_imgPrefix)[1].trim();
          shouldCenter = true;
          child = MaterialButton(
            elevation: 0,
            color: theme.accentColor,
            textColor: theme.textTheme.body1.color,
            child: Text('View image'),
            onPressed: () {
              _launchImageCard(context, theme, imgURL);
            },
          );
        } else {
          shouldCenter = pages.contains(seg);

          child = Text(
            shouldCenter ? 'Page $seg' : seg.trimLeft(),
            style: theme.textTheme.body1.copyWith(
              height:
                  options[HtmlRenderOptions.lineSpacing] ?? defaultLineSpacing,
            ),
          );
        }

        if (shouldCenter) {
          child = Center(child: child);
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: options[HtmlRenderOptions.lineSpacing] * 10,
          ),
          child: child,
        );
//        return child;
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


  static List<String> parseSegments(List<dynamic> nodes, {List<String> pages}) {
    final segments = <String>[];

    // The current segment that will be added to the array
    String currentSegment = '';

    // Index tracking for any changes needed to be done
    int idx = 0;
    int lastAddedIdx = 0;

    // Combine all lines possible for less elements
    nodes.forEach((nodeText) {
      String txt = nodeText.toString();
      // So that we don't start with new lines
      if (idx == 0) {
        txt = txt.trimLeft();
      }
      // Add if not empty
      if (txt.isNotEmpty) {
        if (_isNumeric(txt)) {
          // Handle page numbers
          segments.add(txt);
          if (pages != null) {
            pages.add(txt);
          }
        } else {
          // Check if current segment is valid and does not end with a trimmable char
          if (currentSegment != null &&
              currentSegment.isNotEmpty &&
              currentSegment.trimRight() == currentSegment) {
            currentSegment += ' ';
          }

          if (txt.contains(_imgPrefix)) {
            segments.add(txt);
          } else {
            currentSegment += txt;
            // Only count as a full segment if not adding a single character
            if (txt.trim().length > 1) {
              String checkSegment = currentSegment.trimRight();
              if (checkSegment.endsWith('?') || // Sentences
                  checkSegment.endsWith('.') ||
                  checkSegment.endsWith('!') ||
                  checkSegment.endsWith(':') || // Lists
                  checkSegment.endsWith('=') ||
                  checkSegment.endsWith('"') || // Quotes
                  checkSegment.endsWith("'") ||
                  checkSegment.endsWith('”') || // Fancy quotes
                  checkSegment.endsWith('‘') ||
                  checkSegment.endsWith(']') || // Dialog
                  // Check for ending with ) and not an emote (i.e (ง ´͈౪`͈)ว)
                  (checkSegment.endsWith(')') &&
                      StringTool.endsWithR(
                        checkSegment,
                        RegExp('[A-Za-z0-9]\\)'),
                      ))) {
                segments.add('\n' + currentSegment);
                currentSegment = '';
                lastAddedIdx = idx;
              }
            }
          }
        }
      }
      idx++;
    });

    // Ensure last remaining text is added
    if (lastAddedIdx != idx && currentSegment.trim().isNotEmpty) {
      segments.add('\n' + currentSegment);
    }

    return segments;
  }

  
  static List<String> parseHtmlSegments(String html) {
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
        mappings.add(defaultNodeMapper(n));
      });
    });
    
    return parseSegments(mappings.where((child) => child != null).toList());
  }

  static bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  static bool _isEmpty(String str) {
    str = str.trim();
    return str.isEmpty || str.length == 0;
  }

  static bool _verifyImg(String url) {
    return url.endsWith('.png') ||
        url.endsWith('.gif') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg');
  }

  static void _visitRecursive(Node node, Function(Node) callback) {
    callback(node);
    node.nodes.forEach((n) => _visitRecursive(n, callback));
  }

  static List<Widget> createChildren(
    String html, {
    BuildContext context,
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
      context: context,
      theme: theme,
      options: options,
    );

    return children.where((child) => child != null).toList();
  }

  static _launchImageCard(
    BuildContext context,
    ThemeData theme,
    String imgURL,
  ) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: theme.accentColor,
              content: Card(
                color: theme.accentColor,
                child: FadeInImage.assetNetwork(
                  fit: BoxFit.fill,
                  placeholder: 'assets/images/blank.png',
                  image: imgURL,
                ),
              ),
            ));
  }
}
