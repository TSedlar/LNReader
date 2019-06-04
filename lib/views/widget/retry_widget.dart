import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/views/widget/loader.dart';

class Retry extends StatefulWidget {
  Retry({Key key, this.action}) : super(key: key);

  final Future Function() action;

  _Retry createState() => _Retry();

  static Future exec(
    BuildContext context,
    Future Function() future, {
    bool fixLoader = true,
    bool escapable = true,
  }) {
    final doError = () {
      bool retrying = false;
      showDialog(
        context: context,
        barrierDismissible: escapable,
        builder: (ctx) => AlertDialog(
              title: Text('Network Error'),
              content: Text('Unable to read page due to network error'),
              actions: [
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                    if (fixLoader) {
                      globals.loading.val = false;
                    }
                  },
                ),
                FlatButton(
                  child: Text('Retry'),
                  onPressed: () {
                    retrying = true;
                    if (fixLoader) {
                      globals.loading.val = true;
                    }
                    Navigator.pop(context);
                    exec(context, future, fixLoader: fixLoader);
                  },
                )
              ].where((child) => child != null).toList(),
            ),
      ).then((_) {
        if (!retrying && fixLoader) {
          globals.loading.val = false;
        }
      });
    };

    return future().catchError((_) {
      doError();
    }).timeout(globals.timeoutLength, onTimeout: doError);
  }
}

class _Retry extends State<Retry> {
  bool retrying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Center(
        child: retrying
            ? Loader.makeIndicator()
            : MaterialButton(
                child: Text('Retry'),
                color: Theme.of(context).primaryColor,
                textColor: Theme.of(context).textTheme.title.color,
                onPressed: () {
                  setState(() {
                    retrying = true;
                  });
                  Retry.exec(context, widget.action).then((_) {
                    setState(() {
                      retrying = false;
                    });
                  }, onError: (_) {
                    setState(() {
                      retrying = false;
                    });
                  }).catchError((_) {
                    setState(() {
                      retrying = false;
                    });
                  });
                }),
      ),
    );
  }
}
