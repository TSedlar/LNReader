import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/color_tool.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/sidebar_view.dart';
import 'package:ln_reader/views/widget/custom_tab_view.dart';
import 'package:ln_reader/views/widget/retry_widget.dart';

class HomeArgs {
  HomeArgs({this.poppable, this.previews, this.searchPreviews});

  final bool poppable;
  final Map<String, List<LNPreview>> previews;
  final List<LNPreview> searchPreviews;
}

class HomeView extends StatefulWidget {
  HomeView({Key key, this.previews, this.searchPreviews}) : super(key: key);

  final Map<String, List<LNPreview>> previews;
  final List<LNPreview> searchPreviews;

  @override
  _HomeView createState() => _HomeView();
}

class _HomeView extends State<HomeView> {
  bool searching = false;
  bool submitted = false;

  bool get viewable => widget.previews != null || widget.searchPreviews != null;

  @override
  void initState() {
    super.initState();
    globals.loading.bind(this);
    globals.theme.bind(this);
    globals.source.bind(this);
    globals.source.val.selectedGenres.bind(this);
  }

  _refresh({String query, bool forceSearch = false}) {
    if (query != null || forceSearch) {
      query = (query != null ? query.toLowerCase() : null);
      globals.loading.val = true;
      Retry.exec(
        context,
        () {
          final genres = globals.source.val.selectedGenres.val;
          return globals.source.val.search(query, genres).then((p) {
            _renavigate(searchPreviews: p);
            // return a value to prevent timeout waiting for nav#pop
            return Future.value(true);
          });
        },
      );
    } else {
      globals.loading.val = true;
      Retry.exec(
          context,
          () => globals.source.val.parsePreviews().then((p) {
                _renavigate(previews: p);
                // return a value to prevent timeout waiting for nav#pop
                return Future.value(true);
              }));
    }
  }

  Future _renavigate({
    Map<String, List<LNPreview>> previews,
    List<LNPreview> searchPreviews,
  }) =>
      Navigator.pushNamed(
        context,
        '/home',
        arguments: HomeArgs(
          poppable: widget.previews != null || widget.searchPreviews != null,
          previews: previews,
          searchPreviews: searchPreviews,
        ),
      );

  _showCategoryDialog() {
    final selectedGenres = globals.source.val.selectedGenres.val;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            title: Text('Categories'),
            content: SingleChildScrollView(
              child: Column(
                children: globals.source.val.genres
                    .map(
                      (g) => StatefulBuilder(
                          builder: (ctx, setState) => CheckboxListTile(
                              title: Text(g),
                              value: selectedGenres.contains(g),
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    selectedGenres.add(g);
                                  } else {
                                    selectedGenres.remove(g);
                                  }
                                });
                              })),
                    )
                    .toList(),
              ),
            ),
          ),
    ).then(
      (_) => _refresh(forceSearch: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    globals.homeContext.val = context;
    return globals.loading.val
        ? Loader.create(context)
        : Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            drawer: SidebarView(),
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50.0),
              child: AppBar(
                elevation: 0.0,
                title: (searching
                    ? PreferredSize(
                        preferredSize: Size.fromHeight(48.0),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(hintText: 'Search...'),
                          onSubmitted: (String text) {
                            submitted = true;
                            _refresh(query: text);
                            searching = false;
                          },
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: ColorTool.shade(
                                Theme.of(context).primaryColor, 0.10),
                          ),
                          child: DropdownButton(
                            isExpanded: true,
                            value: globals.source.val,
                            items: globals.sources.values
                                .map((source) => DropdownMenuItem(
                                      value: source,
                                      child: Text(source.name),
                                    ))
                                .toList(),
                            onChanged: (newSource) {},
                          ),
                        ),
                      )),
                actions: [
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () => _showCategoryDialog(),
                  ),
                  IconButton(
                    icon: Icon(searching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        searching = !searching;
                        if (!searching && submitted) {
                          _refresh();
                        }
                        submitted = false;
                      });
                    },
                  ),
                ],
                iconTheme: IconThemeData(
                  color: Theme.of(context).textTheme.headline.color,
                ),
                actionsIconTheme: IconThemeData(
                  color: Theme.of(context).textTheme.headline.color,
                ),
              ),
            ),
            body: (widget.searchPreviews != null
                ? globals.source.val.makePreviewList(
                    context,
                    widget.searchPreviews,
                  )
                : CustomTabView(
                    itemCount:
                        widget.previews != null ? widget.previews.length : 0,
                    tabBuilder: (ctx, i) => Tab(
                          child: Text(widget.previews.keys.elementAt(i)),
                        ),
                    pageBuilder: (ctx, i) => Center(
                          child: globals.source.val.makePreviewList(
                            context,
                            widget.previews.values.elementAt(i),
                          ),
                        ),
                  )),
          );
  }
}
