import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/home_view.dart';
import 'package:ln_reader/views/widget/retry_widget.dart';

class LandingView extends StatefulWidget {
  LandingView({Key key}) : super(key: key);

  @override
  _LandingView createState() => _LandingView();
}

class _LandingView extends State<LandingView> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      globals.loading.val = true;
      Retry.exec(
        context,
        () {
          return globals.source.val.parsePreviews().then((p) {
              globals.loading.val = false;
              if (p == null || p.isEmpty) {
                throw Error();
              } else {
                Navigator.of(context).pushReplacementNamed(
                  '/home',
                  arguments: HomeArgs(
                    poppable: false,
                    previews: p,
                  ),
                );
                // return a value to prevent timeout waiting for nav#pop
                return Future.value(true);
              }
            });
        },
        escapable: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Loader.create(context);
  }
}
