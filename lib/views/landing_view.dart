import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/home_view.dart';

class LandingView extends StatefulWidget {
  LandingView({Key key}) : super(key: key);

  @override
  _LandingView createState() => _LandingView();
}

class _LandingView extends State<LandingView> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      globals.loading.val = true;
      globals.source.val.parsePreviews().then((p) {
        // Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/home',
          arguments: HomeArgs(
            poppable: false,
            previews: p,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Loader.create(context);
  }
}
