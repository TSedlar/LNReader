import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/color_tool.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/widget/section.dart';

class PreviewListView extends StatefulWidget {
  PreviewListView({
    Key key,
    this.favorites,
    this.fromLanding = false,
  }) : super(key: key);

  final bool favorites;
  final bool fromLanding;

  @override
  _PreviewListView createState() => _PreviewListView();
}

class _PreviewListView extends State<PreviewListView> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    globals.offline.bind(this);
    globals.libHome.bind(this);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Loader.create(context);
    }
    globals.homeContext.val = context;
    List<Widget> sourceWidgets = [];
    globals.sources.values.forEach((source) {
      if (widget.favorites) {
        if (source.favorites.seen && source.favorites.val.isNotEmpty) {
          // Add section title
          sourceWidgets.add(Section.create(
            source.name,
            padLeft: 12.0,
            padTop: 12.0,
          ));
          // Add favorites
          sourceWidgets.addAll(
            source.makePreviewWidgets(
              context,
              source.favorites.val,
              onEntryTap: () => setState(() => loading = true),
              onEntryNavPush: () => setState(() => loading = false),
              offline: globals.offline.val,
            ),
          );
        }
      } else {
        if (source.readPreviews.seen && source.readPreviews.val.isNotEmpty) {
          // Sort by latest
          source.readPreviews.val.sort(
            (p1, p2) => p2.lastReadStamp.val.compareTo(p1.lastReadStamp.val),
          );
          // Add section title
          sourceWidgets.add(Section.create(
            source.name,
            padLeft: 12.0,
            padTop: 12.0,
          ));
          // Add recents
          sourceWidgets.addAll(
            source.makePreviewWidgets(
              context,
              source.readPreviews.val,
              onEntryTap: () => setState(() => loading = true),
              onEntryNavPush: () => setState(() => loading = false),
              offline: globals.offline.val,
            ),
          );
        }
      }
    });
    return Scaffold(
      backgroundColor: Theme.of(context).accentColor,
      appBar: AppBar(
        title: Text(
          widget.favorites ? 'Favorites' : 'Recent',
          style: Theme.of(context).textTheme.title,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.title.color,
        ),
      ),
      body: Container(
        color: Theme.of(context).accentColor,
        child: Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: SingleChildScrollView(
            child: Column(children: sourceWidgets),
          ),
        ),
      ),
      floatingActionButton: widget.favorites
          ? SpeedDial(
              overlayColor: Theme.of(context).primaryColor,
              overlayOpacity: 0.2,
              elevation: 2.0,
              animatedIcon: AnimatedIcons.menu_close,
              backgroundColor:
                  ColorTool.shade(Theme.of(context).primaryColor, 0.10),
              foregroundColor: Theme.of(context).textTheme.headline.color,
              children: [
                SpeedDialChild(
                  child: Icon(Icons.home),
                  backgroundColor:
                      globals.libHome.val ? Colors.red : Colors.green,
                  label: globals.libHome.val
                      ? 'Unmark as homepage'
                      : 'Mark as homepage',
                  labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
                  onTap: () {
                    globals.libHome.val = !globals.libHome.val;
                  },
                ),
              ],
            )
          : null,
    );
  }
}
