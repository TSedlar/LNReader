import 'package:html/dom.dart';

class ArticleParser {

  static const _invalidTags = <String>['script', 'video'];
  static const _textTags = <String>['p', 'span'];

  static _visitRecursive(Node node, Function(Node node) callback) {
    callback(node);
    node.nodes.forEach((n) => _visitRecursive(n, callback));
  }

  static int _countTextSize(Node node) {
    int size = 0;
    node.nodes.forEach((n) {
      // text node type
      if (n.nodeType == 3) {
        size += n.text.trim().length;
      } else if (n.nodes.isNotEmpty) {
        final tag = n.nodes[0].parent.localName.toLowerCase();
        if (_textTags.contains(tag)) {
          size += n.text.trim().length;
        }
      }
    });
    return size;
  }

  static Element getArticleElement(Document document) {
    Node largest;
    int longest = 0;

    document.body.nodes.forEach((node) {
      if (node.nodes.length > 0) {
        final tag = node.nodes[0].parent.localName.toLowerCase();
        if (!_invalidTags.contains(tag)) {
          _visitRecursive(node, (n) {
            final size = _countTextSize(n);
            if (size > longest) {
              largest = n;
              longest = size;
            }
          });
        }
      }
    });

    if (largest != null && largest.nodes.isNotEmpty) {
      return largest.nodes[0].parent;
    }

    return null;
  }
}
