import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/hex_color.dart';

class Loader {
  static Widget makeIndicator([ThemeData theme]) =>
      CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          (theme != null ? theme.textTheme.headline.color : HexColor(globals.theme.val['foreground_accent'])),
        ),
      );

  static Widget create(BuildContext context, [ThemeData theme]) => Container(
        color: (theme != null ? theme : Theme.of(context)).accentColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [makeIndicator(theme)],
          ),
        ),
      );
}
