import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/hex_color.dart';

class Section {
  static Widget create(
    String title, {
    double padLeft = 0,
    double padRight = 0,
    double padTop = 8.0,
    double padBottom = 4.0,
    bool useGlobalFGA = true,
  }) =>
      Padding(
          padding: EdgeInsets.only(
            left: padLeft,
            right: padRight,
            top: padTop,
            bottom: padBottom,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: useGlobalFGA
                    ? HexColor(globals.theme.val['foreground_accent'])
                    : null,
              ),
            ),
          ));
}
