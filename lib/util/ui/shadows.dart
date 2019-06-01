import 'package:flutter/material.dart';

class Shadows {
  static List<Shadow> textOutline(double size) {
    return <Shadow>[
      Shadow(
        // bottomLeft
        offset: Offset(-size, -size),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // bottomRight
        offset: Offset(size, -size),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // topRight
        offset: Offset(size, size),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // topLeft
        offset: Offset(-size, size),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // left
        offset: Offset(-size, 0),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // right
        offset: Offset(size, 0),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // bottom
        offset: Offset(0, size),
        blurRadius: size,
        color: Colors.black,
      ),
      Shadow(
        // top
        offset: Offset(0, -size),
        blurRadius: size,
        color: Colors.black,
      ),
    ];
  }
}