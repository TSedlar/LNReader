import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/observable.dart';
import 'package:ln_reader/util/ui/hex_color.dart';

class Loader {
  static final text = ObservableValue<String>();
  static final extendedText = ObservableValue<String>();

  static Widget makeIndicator([ThemeData theme]) => CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          (theme != null
              ? theme.textTheme.headline.color
              : HexColor(globals.theme.val['foreground_accent'])),
        ),
      );

  static Widget create(BuildContext context, [ThemeData theme]) =>
      LoaderScaffold(context, theme: theme);
}

class LoaderScaffold extends StatefulWidget {
  LoaderScaffold(this.buildContext, {Key key, this.theme}) : super(key: key);

  final BuildContext buildContext;
  final ThemeData theme;

  @override
  _LoaderScaffold createState() => _LoaderScaffold();
}

class _LoaderScaffold extends State<LoaderScaffold> {
  @override
  void initState() {
    super.initState();
    Loader.text.bind(this);
    Loader.extendedText.bind(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: (widget.theme != null
                  ? widget.theme
                  : Theme.of(widget.buildContext))
              .accentColor,
          child: Stack(
            children: [
              Loader.extendedText.seen
                  ? Positioned(
                      top: 0.0,
                      child: Container(
                        color: widget.theme != null
                            ? widget.theme.primaryColor
                            : Theme.of(widget.buildContext).primaryColor,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 30.0,
                          child: Center(
                            child: Text(
                              Loader.extendedText.val,
                              style: widget.theme != null
                                  ? widget.theme.textTheme.body1
                                  : Theme.of(widget.buildContext)
                                      .textTheme
                                      .body1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: Loader.makeIndicator(widget.theme),
                    ),
                    Text(
                      Loader.text.seen ? Loader.text.val : 'Loading...',
                      style: widget.theme != null
                          ? widget.theme.textTheme.subhead
                          : Theme.of(widget.buildContext).textTheme.subhead,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ].where((child) => child != null).toList(),
          ),
        ),
      ),
    );
  }
}
