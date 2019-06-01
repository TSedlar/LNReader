import 'dart:math';

import 'package:flutter/material.dart';

class ColorTool {
  static bool isBright(Color inColor) {
    int sum = (inColor.red + inColor.green + inColor.blue); // max 255*3 = 765
    return sum >= 382; // 765/2
  }

  static Color shade(Color inColor, double inAmount) {
    if (isBright(inColor)) {
      inAmount *= 0.8; // don't shade bright colors too much
      inAmount *= -1.0; // invert to negative
    }
    return Color.fromARGB(
      inColor.alpha,
      max(0.0, min(255.0, inColor.red + 255 * inAmount)).toInt(),
      max(0.0, min(255.0, inColor.green + 255 * inAmount)).toInt(),
      max(0.0, min(255.0, inColor.blue + 255 * inAmount)).toInt(),
    );
  }
}
