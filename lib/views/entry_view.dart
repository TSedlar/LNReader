import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ln_reader/util/net/global_web_view.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:share/share.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/util/ui/color_tool.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/widget/section.dart';

class EntryArgs {
  EntryArgs({this.preview, this.entry, this.nextChapter});

  final LNPreview preview;
  final LNEntry entry;
  final LNChapter nextChapter;
}

class EntryView extends StatefulWidget {
  EntryView({Key key, this.preview, this.entry}) : super(key: key);

  final LNPreview preview;
  final LNEntry entry;

  @override
  _EntryView createState() => _EntryView();
}

class _EntryView extends State<EntryView> {
  @override
  void initState() {
    super.initState();
    widget.preview.lastRead.bind(this);
    widget.preview.ascending.bind(this);
    widget.preview.source.favorites.bind(this);
    globals.loading.bind(this);
    globals.readerMode.bind(this);
  }

  Widget _txt(String str, [double bottomPadding = 6.0]) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Text(
          str,
          textScaleFactor: 0.8,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: HexColor(
              globals.theme.val['foreground_accent'],
            ),
          ),
        ),
      ),
    );
  }

  Widget _makeInfo() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        height: 173,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              columnWidths: {
                0: FlexColumnWidth(40),
                1: FlexColumnWidth(60),
              },
              children: [
                TableRow(children: [
                  _txt('Authors:'),
                  _txt(widget.entry.authors.join(', ')),
                ]),
                TableRow(children: [
                  _txt('Aliases:'),
                  _txt(
                    widget.entry.aliases.isEmpty
                        ? 'N/A'
                        : widget.entry.aliases.join(', '),
                  ),
                ]),
                TableRow(children: [
                  _txt('Released:'),
                  _txt(widget.entry.releaseDate),
                ]),
                TableRow(children: [
                  _txt('Status:', 7.0),
                  _txt(widget.entry.status, 7.0),
                ]),
                TableRow(children: [
                  _txt('Translator:'),
                  _txt(widget.entry.translator),
                ]),
              ],
            ),
            _makeGenres(),
          ],
        ),
      ),
    );
  }

  Widget _makeGenres([int maxChips = 0]) {
    if (maxChips == 0) {
      // (device_width - (cover_width + padding)) / (chip_width + chip_right_padding)
      maxChips = ((MediaQuery.of(context).size.width - 235.0) / 41.0).floor();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: widget.entry.genres
          .sublist(0, min(maxChips, widget.entry.genres.length))
          .map(
            (g) => Container(
                  padding: EdgeInsets.only(right: 2.5),
                  child: Chip(
                    backgroundColor: ColorTool.shade(
                      Theme.of(context).primaryColor,
                      0.10,
                    ),
                    label: Container(
                      constraints:
                          BoxConstraints(minWidth: 38.0, maxWidth: 38.0),
                      child: Center(
                        child: Text(
                          g,
                          textScaleFactor: 0.55,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    labelStyle: Theme.of(context).textTheme.body1.copyWith(
                          color: Theme.of(context).textTheme.headline.color,
                        ),
                  ),
                ),
          )
          .toList(),
    );
  }

  Future _openChapter(LNChapter chapter) {
    // Ensure chapter is seen and not the same as the one chosen to open
    if (widget.preview.lastRead.seen &&
        widget.preview.lastRead.val.link != chapter.link) {
      widget.preview.lastRead.val.lastPosition =
          widget.preview.lastRead.val.scrollLength;
    }
    widget.preview.markLastRead(chapter);
    globals.loading.val = true;
    return chapter.source
        .launchView(context, chapter,
            globals.readerMode.val && chapter.source.allowsReaderMode)
        .then((view) => Future.value(() {
              globals.loading.val = false;
              return view;
            }));
  }

  Widget _makeChapterCard(LNChapter chapter, {String title, String subtitle}) {
    final nextChapter = widget.preview.lastRead.seen
        ? (widget.preview.lastRead.val.nearCompletion()
            ? widget.entry.nextChapter(widget.preview.lastRead.val)
            : widget.preview.lastRead.val)
        : null;

    bool read = nextChapter != null && chapter.index > nextChapter.index;

    if (title == null) {
      title = chapter.title;
    }

    if (subtitle == null) {
      subtitle = 'Release: ${chapter.date}';
    }

    return GestureDetector(
      onTap: () => _openChapter(chapter),
      child: Card(
        color: Theme.of(context).primaryColor,
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              decoration: read ? TextDecoration.lineThrough : null,
              color: read
                  ? Theme.of(context).textTheme.body1.color // read
                  : Theme.of(context).textTheme.headline.color, // unread,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              read
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).textTheme.headline.color,
                    )
                  : null,
              Theme(
                data: Theme.of(context).copyWith(
                  cardColor:
                      ColorTool.shade(Theme.of(context).primaryColor, 0.10),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).textTheme.headline.color,
                  ),
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'mark_last_read',
                          child: Text('Mark last read'),
                        ),
                        PopupMenuItem(
                          value: 'open_external',
                          child: Text('Open in browser'),
                        ),
                        PopupMenuItem(
                          value: 'share_link',
                          child: Text('Share link'),
                        ),
                      ],
                  onSelected: (action) {
                    if (action == 'mark_last_read') {
                      print('Marked last read');
                      chapter.lastPosition = chapter.scrollLength;
                      widget.preview.markLastRead(chapter);
                    } else if (action == 'open_external') {
                      print('Opening in external browser...');
                      GlobalWebView.launchExternal(context, chapter.link);
                    } else if (action == 'share_link') {
                      print('Sharing link...');
                      Share.share(chapter.link);
                    }
                  },
                ),
              ),
            ].where((child) => child != null).toList(),
          ),
        ),
      ),
    );
  }

  Widget _makeChapterList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        final chapter = widget.preview.ascending.val
            ? widget.entry.chapters[widget.entry.chapters.length - 1 - index]
            : widget.entry.chapters[index];
        return _makeChapterCard(chapter);
      }, childCount: widget.entry.chapters.length),
    );
  }

  Widget _makeSpeedDial() {
    return SpeedDial(
      overlayColor: Theme.of(context).primaryColor,
      overlayOpacity: 0.2,
      elevation: 2.0,
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: ColorTool.shade(Theme.of(context).primaryColor, 0.10),
      foregroundColor: Theme.of(context).textTheme.headline.color,
      children: [
        SpeedDialChild(
          child: Icon(
            widget.preview.ascending.val
                ? Icons.arrow_drop_down
                : Icons.arrow_drop_up,
            size: 30.0,
          ),
          backgroundColor: Colors.green,
          label: 'Sort ' +
              (widget.preview.ascending.val ? 'descending' : 'ascending'),
          labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
          onTap: () {
            widget.preview.ascending.val = !widget.preview.ascending.val;
          },
        ),
        SpeedDialChild(
          child: widget.preview.isFavorite()
              ? Icon(Icons.delete)
              : Icon(Icons.star),
          backgroundColor:
              widget.preview.isFavorite() ? Colors.red : Colors.amber,
          label: widget.preview.isFavorite()
              ? 'Remove from favorites'
              : 'Add to favorites',
          labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
          onTap: () {
            if (widget.preview.isFavorite()) {
              widget.preview.removeFromFavorites();
            } else {
              widget.preview.favorite();
            }
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.book),
          backgroundColor: Colors.orange,
          label: 'Read next chapter',
          labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
          onTap: () {
            if (widget.preview.lastRead.seen) {
              final next =
                  widget.entry.nextChapter(widget.preview.lastRead.val);
              if (next != null) {
                _openChapter(next);
              } else {
                // there is no other chapter
                print('You are up-to-date!');
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text('Up-to-date'),
                        content: Text('You have read the latest release'),
                      ),
                );
              }
            } else {
              _openChapter(widget.entry.firstChapter());
            }
          },
        ),
        SpeedDialChild(
          child: globals.readerMode.val
              ? Icon(Icons.explore)
              : Icon(Icons.import_contacts),
          backgroundColor:
              globals.readerMode.val ? Colors.blue : Colors.grey[800],
          label: globals.readerMode.val
              ? 'Enable Web Reader'
              : 'Enable Reader Mode',
          labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
          onTap: () => globals.readerMode.val = !globals.readerMode.val,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextChapter = widget.preview.lastRead.seen
        ? (widget.preview.lastRead.val.nearCompletion()
            ? widget.entry.nextChapter(widget.preview.lastRead.val)
            : widget.preview.lastRead.val)
        : null;
    return globals.loading.val
        ? Loader.create(context)
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.preview.name,
                style: Theme.of(context).textTheme.title,
              ),
              iconTheme: IconThemeData(
                color: Theme.of(context).textTheme.headline.color,
              ),
            ),
            body: Container(
              color: Theme.of(context).accentColor,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 128,
                                  height: 166,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10.0),
                                    child: ClipRRect(
                                      borderRadius:
                                          new BorderRadius.circular(5.0),
                                      child: FadeInImage.assetNetwork(
                                        fadeInDuration:
                                            Duration(milliseconds: 250),
                                        placeholder: 'assets/images/blank.png',
                                        image: widget.preview.coverURL,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                                _makeInfo(),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 3.0, bottom: 6.0),
                              child: Text(
                                widget.entry.description
                                    .replaceAll(r'\n', '\n'),
                                style: TextStyle(
                                  color: ColorTool.shade(
                                    HexColor(
                                      globals.theme.val['foreground_accent'],
                                    ),
                                    0.25,
                                  ),
                                ),
                              ),
                            ),
                            nextChapter != null
                                ? Column(
                                    children: [
                                      Section.create('Continue Reading: ' +
                                          (nextChapter.started()
                                              ? nextChapter.percentReadString()
                                              : '')),
                                      _makeChapterCard(nextChapter),
                                    ],
                                  )
                                : null,
                            Section.create('Chapters:'),
                          ].where((w) => w != null).toList(),
                        ),
                      ]),
                    ),
                    _makeChapterList(),
                  ],
                ),
              ),
            ),
            floatingActionButton: _makeSpeedDial(),
          );
  }
}
