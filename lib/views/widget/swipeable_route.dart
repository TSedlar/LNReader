import 'package:flutter/cupertino.dart';

class SwipeableRoute extends CupertinoPageRoute {
  SwipeableRoute({
    WidgetBuilder builder,
    String title,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          title: title,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
