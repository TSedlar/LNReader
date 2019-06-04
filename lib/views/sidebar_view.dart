import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/net/global_web_view.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/views/preview_list_view.dart';

class SidebarView extends StatefulWidget {
  SidebarView({Key key}) : super(key: key);

  @override
  _SidebarView createState() => _SidebarView();
}

class _SidebarView extends State<SidebarView> {
  String githubREADME =
      'https://github.com/TSedlar/LNReader/blob/master/README.md';

  @override
  Widget build(BuildContext context) {
    final fgAccent = Theme.of(context)
        .textTheme
        .subhead
        .copyWith(color: HexColor(globals.theme.val['foreground_accent']));
    return Drawer(
      child: Container(
        color: Theme.of(context).accentColor,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              // ListView contains a group of widgets that scroll inside the drawer
              child: ListView(
                children: [
                  SizedBox(
                    height: 120.0,
                    child: DrawerHeader(
                      child: Container(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'LN Reader',
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home, color: fgAccent.color),
                    title: Text('Home', style: fgAccent),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.star, color: fgAccent.color),
                    title: Text('Favorites', style: fgAccent),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              PreviewListView(favorites: true),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.restore, color: fgAccent.color),
                    title: Text('Recent', style: fgAccent),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => PreviewListView(
                                favorites: false,
                              ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            Container(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(children: [
                  ListTile(
                    leading: Icon(Icons.local_cafe, color: fgAccent.color),
                    title: Text('Support Development', style: fgAccent),
                    onTap: () =>
                        GlobalWebView.launchExternal(context, githubREADME),
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: fgAccent.color),
                    title: Text('About', style: fgAccent),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: fgAccent.color),
                    title: Text('Settings', style: fgAccent),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
