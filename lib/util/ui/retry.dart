import 'package:flutter/material.dart';

class Retry {

  static Future<T> exec<T>(
    BuildContext context,
    Future<T> Function() future, {
    Duration timeout = const Duration(seconds: 30),
    bool escapable = true,
    Function() onRetry,
    Function() onFail,
  }) async {
    final doError = () async {
      bool retrying = false;
      await showDialog(
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
                    if (onFail != null) {
                      onFail();
                    }
                  },
                ),
                FlatButton(
                  child: Text('Retry'),
                  onPressed: () {
                    retrying = true;
                    if (onRetry != null) {
                      onRetry();
                    }
                    Navigator.pop(context);
                    exec(
                      context,
                      future,
                      escapable: escapable,
                      onRetry: onRetry,
                      onFail: onFail,
                    );
                  },
                )
              ].where((child) => child != null).toList(),
            ),
      );
      if (!retrying && onFail != null) {
        onFail();
      }
    };

    T result;

    try {
      result = await future().timeout(timeout);
    } catch (err) {
      doError();
    }

    return result;
  }
}
