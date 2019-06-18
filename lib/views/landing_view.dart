import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/retry.dart';
import 'package:ln_reader/views/preview_list_view.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/home_view.dart';

class LandingView extends StatefulWidget {
  LandingView({
    Key key,
    this.forceHome = false,
    this.forceChoose = false,
  }) : super(key: key);

  final bool forceHome;
  final bool forceChoose;

  @override
  _LandingView createState() => _LandingView();
}

class _LandingView extends State<LandingView> {
  bool checking = false;
  bool forceChoose = false;

  @override
  void initState() {
    super.initState();

    globals.offline.bind(this);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!globals.firstRun && !widget.forceChoose) {
        if (globals.libHome.val && !widget.forceHome) {
          await Future.delayed(Duration(seconds: 2));
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PreviewListView(
                    favorites: true,
                    fromLanding: true,
                  ),
            ),
          ).then((_) {
            _navigateToHome();
          });
        } else {
          _navigateToHome();
        }
      }
    });
  }

  @override
  void dispose() {
    globals.offline.disposeAt(this);
    super.dispose();
  }

  void _navigateToHome([LNSource source]) async {
    if (source == null) {
      source = globals.source.val;
    } else {
      globals.source.val = source;
    }

    setState(() {
      checking = true;
    });

    final html = globals.offline.val
        ? 'offline'
        : await Retry.exec(context, () {
            return source.fetchPreviews();
          }, escapable: false);

    if (html != null) {
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: HomeArgs(
          poppable: false,
          source: source,
          html: html == 'offline' ? null : html,
        ),
      );
      setState(() {
        checking = false;
      });
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).primaryColor,
              title: Text(
                'Failed...',
                style: Theme.of(context).textTheme.subtitle,
              ),
              content: Text(
                'Connection faulty...',
                style: Theme.of(context).textTheme.subtitle,
              ),
              actions: [
                FlatButton(
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  onPressed: () {
                    setState(() {
                      forceChoose = true;
                    });
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                    child: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToHome(source);
                    }),
              ],
            ),
      );
    }
  }

  Widget _createFirstRunPage() {
    final children = <Widget>[
      Padding(
        padding: EdgeInsets.only(bottom: 3.0),
        child: SizedBox.fromSize(
          size: Size(double.infinity, 35.0),
          child: Card(
            color: Theme.of(context).primaryColor,
            child: Center(
              child: Text(
                'Please choose a source to use!',
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ];

    globals.sources.keys.forEach((key) {
      final source = globals.sources[key];
      children.add(Padding(
        padding: EdgeInsets.only(bottom: 3.0),
        child: GestureDetector(
          onTap: () => _navigateToHome(source),
          child: Card(
            color: Theme.of(context).primaryColor,
            child: ListTile(
              leading: Image(
                width: 40.0,
                height: 40.0,
                image: AssetImage(source.logoAsset),
                fit: BoxFit.fill,
              ),
              title: Text(
                source.name,
                style: Theme.of(context).textTheme.subhead,
              ),
              subtitle: Text(
                'Language: ${source.lang}',
                style: Theme.of(context).textTheme.caption,
              ),
              trailing: MaterialButton(
                minWidth: 60.0,
                color: Theme.of(context).accentColor,
                child: Text(
                  'Choose',
                  style: Theme.of(context).textTheme.caption,
                ),
                onPressed: () => _navigateToHome(source),
              ),
            ),
          ),
        ),
      ));
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (forceChoose || widget.forceChoose || globals.firstRun) && !checking
        ? _createFirstRunPage()
        : Loader.create(context);
  }
}
