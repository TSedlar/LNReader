import 'package:html/dom.dart';

class DomTool {

  static Node next (Node node, {int skip: 1}) {
    if (node == null) {
      return null;
    }
    final pN = node.parentNode;
    if (pN == null) {
      return null;
    }
    final pNodes = pN.nodes;
    int idx = pNodes.indexOf(node);
    if (idx >= 0 && idx + skip < pNodes.length) {
      return pNodes[idx + skip];
    } else {
      return null;
    }
  }
}