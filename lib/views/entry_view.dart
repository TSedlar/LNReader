import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:interactive_webview/interactive_webview.dart';
import 'package:ln_reader/util/ui/html_renderer.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:ln_reader/novel/ln_isolate.dart';
import 'package:ln_reader/util/net/connection_status.dart';
import 'package:ln_reader/util/net/webview_reader.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/util/ui/color_tool.dart';
import 'package:ln_reader/views/widget/loader.dart';
import 'package:ln_reader/views/widget/section.dart';

class EntryArgs {
  EntryArgs({this.preview, this.html, this.usingCache});

  final LNPreview preview;
  final String html;
  final bool usingCache;
}

class EntryView extends StatefulWidget {
  EntryView({Key key, this.preview, this.html, this.usingCache})
      : super(key: key);

  final LNPreview preview;
  final String html;
  final bool usingCache;

  @override
  _EntryView createState() => _EntryView();
}

class _EntryView extends State<EntryView> {
  String html;
  LNEntry entry;
  bool processingAction = false;
  List<int> selectedChapters = [];

  @override
  void initState() {
    super.initState();

    setState(() => html = widget.html);

    widget.preview.lastRead.bind(this);
    widget.preview.ascending.bind(this);
    widget.preview.source.favorites.bind(this);
    globals.readerMode.bind(this);
    globals.offline.bind(this);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Set entry if locally cached
      if (widget.preview.entry != null) {
        print('Using locally cached entry');
        setState(() => entry = widget.preview.entry);
      }

      // Check for updates in background
      if (!globals.offline.val) {
        print('Online, updating entry...');

        if (html == null && widget.usingCache) {
          print('Updating entry...');
          String fetchedHTML =
              await widget.preview.source.fetchEntry(widget.preview);
          if (fetchedHTML != null) {
            if (mounted) {
              setState(() => html = fetchedHTML);
            }
          }
          print('Updated entry');
        }

        if (html != null) {
          print('Updated entry from html');

          // Retrieve entry in background
          final _entry =
              await LNIsolate.parseEntry(widget.preview.source, html);

          // Set preview entry
          widget.preview.entry = _entry;

          // Write out the data for offline use
          widget.preview.writeEntryData(_entry);

          // Update entry state
          if (mounted) {
            setState(() => entry = _entry);
          }
        }
      }

      // Download and cache the cover image
      widget.preview.downloadCover(entry);
    });
  }

  @override
  void dispose() {
    // Dispose of observables
    widget.preview.lastRead.disposeAt(this);
    widget.preview.ascending.disposeAt(this);
    widget.preview.source.favorites.disposeAt(this);
    globals.readerMode.disposeAt(this);
    globals.offline.disposeAt(this);

    super.dispose();
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
    var infoEntries = <MapEntry<String, String>>[];

    if (entry.authors.isNotEmpty) {
      infoEntries.add(MapEntry('Authors:', entry.authors.join(', ')));
    }

    if (entry.aliases.isNotEmpty) {
      infoEntries.add(MapEntry('Aliases:', entry.aliases.join(', ')));
    }

    if (entry.releaseDate != null && entry.releaseDate != 'N/A') {
      infoEntries.add(MapEntry('Released:', entry.releaseDate));
    }

    if (entry.status != null && entry.status != 'N/A') {
      infoEntries.add(MapEntry('Status:', entry.status));
    }

    if (entry.translator != null && entry.translator != 'N/A') {
      infoEntries.add(MapEntry('Translator:', entry.translator));
    }

    if (entry.views != null && entry.views != 'N/A') {
      infoEntries.add(MapEntry('Views:', entry.views));
    }

    if (entry.ranking != null && entry.ranking != 'N/A') {
      infoEntries.add(MapEntry('Ranking:', entry.ranking));
    }

    if (entry.lastUpdated != null && entry.lastUpdated != 'N/A') {
      infoEntries.add(MapEntry('Updated:', entry.lastUpdated));
    }

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
              children: infoEntries
                  .sublist(0, min(5, infoEntries.length))
                  .map((e) => TableRow(children: [
                        _txt(e.key),
                        _txt(e.value),
                      ]))
                  .toList(),
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
    final chipWidth = entry.genres.length == 1 ? -1 : 38.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: entry.genres
          .sublist(0, min(maxChips, entry.genres.length))
          .map(
            (g) => Container(
                  padding: EdgeInsets.only(right: 2.5),
                  child: Chip(
                    backgroundColor: ColorTool.shade(
                      Theme.of(context).primaryColor,
                      0.10,
                    ),
                    label: Container(
                      constraints: chipWidth <= 0
                          ? null
                          : BoxConstraints(
                              minWidth: chipWidth,
                              maxWidth: chipWidth,
                            ),
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

  Future _openChapter(LNChapter chapter) async {
    print('call: _openChapter');

    if (globals.offline.val && !chapter.isDownloaded(widget.preview)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).accentColor,
              title: Text(
                'Offline',
                style: Theme.of(context).textTheme.subtitle,
              ),
              content: Text(
                'You are offline and the next chapter is not downloaded!',
                style: Theme.of(context).textTheme.caption,
              ),
              actions: [
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(
                    'Okay',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return Future.value(false);
    }

    // Start the load interface
    setState(() {
      processingAction = true;
    });

    // Ensure chapter is seen and not the same as the one chosen to open
    if (widget.preview.lastRead.seen &&
        widget.preview.lastRead.val.link != chapter.link) {
      widget.preview.lastRead.val.lastPosition =
          widget.preview.lastRead.val.scrollLength;
    }

    widget.preview.markLastRead(chapter);

    bool readerMode = globals.readerMode.val && chapter.source.allowsReaderMode;

    print('launching view...');

    final view = await chapter.source.launchView(
      context: context,
      preview: widget.preview,
      chapter: chapter,
      readerMode: readerMode,
      offline: globals.offline.val,
    );

    setState(() => processingAction = false);

    return view;
  }

  // TODO: make a download queue + view
  _downloadChapters(List<int> chapters) async {
    setState(() => processingAction = true);

    final failed = <LNChapter>[];
    int currentIdx = 1;

    for (final chIdx in chapters) {
      // Debug
      print('Downloading $currentIdx/${chapters.length}');
      Loader.extendedText.val =
          'Downloading chapter: $currentIdx/${chapters.length}';

      // Convert chapter idx -> LNChapter
      final chapter = entry.chapters.firstWhere((ch) => ch.index == chIdx);

      // Only download if not downloaded
      if (!chapter.isDownloaded(widget.preview)) {
        final source = await chapter.download(context, widget.preview);
        if (source == null) {
          // If source is null, this failed to download
          failed.add(chapter);
        }

        // Ensure clean slate so no duplicate chapter downloads
        InteractiveWebView().loadUrl('about:blank');
        await Future.delayed(Duration(seconds: 1));
      }

      currentIdx++;
    }

    if (failed.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).accentColor,
              title: Text(
                'Failed...',
                style: Theme.of(context).textTheme.subtitle,
              ),
              content: Text(
                'The ${failed.length} chapter(s) failed to download',
                style: Theme.of(context).textTheme.caption,
              ),
              actions: [
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(
                    'Okay',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }

    setState(() => processingAction = false);
  }

  _exportChapters(List<int> chapters) async {
    final Map<String, List<int>> fileBytes = {};
    for (final chIdx in chapters) {
      final chapter = entry.chapters.firstWhere((ch) => ch.index == chIdx);
      final name = widget.preview.name + ' - ' + chapter.title + '.txt';
      final rawContent = await widget.preview.getChapterContent(chapter);
      final content = widget.preview.source.makeReaderContent(rawContent);
      final txtData = HtmlRenderer.parseHtmlSegments(content).join('\n');
      final bytes = utf8.encode(txtData);
      fileBytes[name] = bytes;
    };
    await Share.files('Export Chapter(s)', fileBytes, 'text/plain');
  }

  Widget _makeChapterCard(LNChapter chapter, {String title, String subtitle}) {
    final nextChapter = widget.preview.lastRead.seen
        ? (widget.preview.lastRead.val.nearCompletion()
            ? entry.nextChapter(widget.preview.lastRead.val)
            : widget.preview.lastRead.val)
        : null;

    bool read = nextChapter != null && chapter.index > nextChapter.index;

    // Early return empty widget if hiding read chapters
    if (globals.hideRead.val && read) {
      return Container();
    }

    if (title == null) {
      title = chapter.title;
    }

    if (subtitle == null && chapter.date != null && chapter.date != 'N/A') {
      subtitle = 'Release: ${chapter.date}';
    }

    return Opacity(
      opacity: globals.offline.val
          ? (chapter.isDownloaded(widget.preview) ? 1.0 : 0.5)
          : 1.0,
      child: Card(
        color: selectedChapters.contains(chapter.index)
            ? ColorTool.shade(Theme.of(context).primaryColor, 0.10)
            : Theme.of(context).primaryColor,
        child: ListTile(
          onLongPress: () {
            setState(() {
              if (selectedChapters.contains(chapter.index)) {
                selectedChapters.remove(chapter.index);
              } else {
                selectedChapters.add(chapter.index);
              }
            });
          },
          onTap: () {
            if (selectedChapters.isNotEmpty) {
              setState(() {
                if (selectedChapters.contains(chapter.index)) {
                  selectedChapters.remove(chapter.index);
                } else {
                  selectedChapters.add(chapter.index);
                }
              });
            } else {
              if (globals.offline.val) {
                if (chapter.isDownloaded(widget.preview)) {
                  _openChapter(chapter);
                }
              } else {
                _openChapter(chapter);
              }
            }
          },
          title: Text(
            title.replaceFirst(widget.preview.name, '').trimLeft(),
            style: TextStyle(
              decoration: read ? TextDecoration.lineThrough : null,
              color: read
                  ? Theme.of(context).textTheme.body1.color // read
                  : Theme.of(context).textTheme.headline.color, // unread,
            ),
          ),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show downloaded if it isn't read
              !read && chapter.isDownloaded(widget.preview)
                  ? Icon(
                      Icons.cloud_done,
                      color: Theme.of(context).textTheme.headline.color,
                    )
                  : null,
              read
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).textTheme.headline.color,
                    )
                  : null,
              selectedChapters.isNotEmpty
                  ? null
                  : Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: ColorTool.shade(
                            Theme.of(context).primaryColor, 0.10),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).textTheme.headline.color,
                        ),
                        itemBuilder: (context) => [
                              globals.offline.val ||
                                      chapter.isDownloaded(widget.preview)
                                  ? (chapter.isDownloaded(widget.preview)
                                      ? PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        )
                                      : null)
                                  : PopupMenuItem(
                                      value: 'download',
                                      child: Text('Download'),
                                    ),
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
                              PopupMenuItem(
                                value: 'export',
                                child: Text('Export chapter'),
                              ),
                            ].where((child) => child != null).toList(),
                        onSelected: (action) async {
                          if (action == 'download') {
                            _downloadChapters([chapter.index]);
                          } else if (action == 'delete') {
                            setState(() {
                              chapter.deleteFile(widget.preview);
                            });
                          } else if (action == 'mark_last_read') {
                            print('Marked last read');
                            chapter.lastPosition = chapter.scrollLength;
                            widget.preview.markLastRead(chapter);
                          } else if (action == 'open_external') {
                            print('Opening in external browser...');
                            WebviewReader.launchExternal(context, chapter.link);
                          } else if (action == 'share_link') {
                            print('Sharing link...');
                            Share.text('Share Chapter Link', chapter.link, 'text/plain');
                          } else if (action == 'export') {
                            await _downloadChapters([chapter.index]);
                            await _exportChapters([chapter.index]);
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
            ? entry.chapters[entry.chapters.length - 1 - index]
            : entry.chapters[index];
        return _makeChapterCard(chapter);
      }, childCount: entry.chapters.length),
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
              final next = entry == null
                  ? null
                  : widget.preview.lastRead.seen
                      ? (widget.preview.lastRead.val.nearCompletion()
                          ? entry.nextChapter(widget.preview.lastRead.val)
                          : widget.preview.lastRead.val)
                      : null;
              if (next != null) {
                _openChapter(next);
              } else {
                // there is no other chapter
                print('You are up-to-date!');
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).accentColor,
                        title: Text(
                          'Up to date!',
                          style: Theme.of(context).textTheme.subtitle,
                        ),
                        content: Text(
                          'There is not another chapter after this',
                          style: Theme.of(context).textTheme.caption,
                        ),
                        actions: [
                          MaterialButton(
                            color: Theme.of(context).primaryColor,
                            child: Text(
                              'Okay',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                );
              }
            } else {
              _openChapter(entry.firstChapter());
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
    final nextChapter = entry == null
        ? null
        : widget.preview.lastRead.seen
            ? (widget.preview.lastRead.val.nearCompletion()
                ? entry.nextChapter(widget.preview.lastRead.val)
                : widget.preview.lastRead.val)
            : null;
    return (html != null || entry != null) &&
            (entry == null || processingAction)
        ? Loader.create(context)
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.preview.name,
                style: Theme.of(context).textTheme.title,
              ),
              actions: [
                selectedChapters.isEmpty
                    ? null
                    : Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: ColorTool.shade(
                              Theme.of(context).primaryColor, 0.10),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).textTheme.headline.color,
                          ),
                          itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'mark_read',
                                  child: Text('Mark read'),
                                ),
                                globals.offline.val
                                    ? null
                                    : PopupMenuItem(
                                        value: 'download',
                                        child: Text('Download'),
                                      ),
                                globals.offline.val
                                    ? null
                                    : PopupMenuItem(
                                        value: 'export',
                                        child: Text('Export'),
                                      ),
                                PopupMenuItem(
                                  value: 'select_all',
                                  child: Text('Select all'),
                                ),
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Cancel'),
                                ),
                              ].where((child) => child != null).toList(),
                          onSelected: (action) async {
                            if (action == 'mark_read') {
                              // Remember this is in descending order by default
                              selectedChapters.sort(
                                (ch1, ch2) => ch1 - ch2,
                              );
                              // Mark chapters read
                              entry.chapters.where((ch) {
                                return ch.index == selectedChapters.first;
                              }).forEach((ch) {
                                ch.lastPosition = ch.scrollLength;
                                widget.preview.markLastRead(ch);
                              });
                              setState(() {
                                selectedChapters.clear();
                              });
                            } else if (action == 'download') {
                              _downloadChapters(selectedChapters.toList());
                              setState(() => selectedChapters.clear());
                            } else if (action == 'export') {
                              await _downloadChapters(selectedChapters.toList());
                              await _exportChapters(selectedChapters.toList());
                              setState(() => selectedChapters.clear());
                            } else if (action == 'select_all') {
                              setState(() {
                                selectedChapters.clear();
                                selectedChapters.addAll(
                                  entry.chapters.map((ch) => ch.index),
                                );
                              });
                            } else if (action == 'cancel') {
                              setState(() => selectedChapters.clear());
                            }
                          },
                        ),
                      ),
              ].where((child) => child != null).toList(),
              iconTheme: IconThemeData(
                color: Theme.of(context).textTheme.headline.color,
              ),
            ),
            body: html == null && entry == null
                ? ConnectionStatus.createOfflineWidget(context)
                : Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 128,
                                        height: 166,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                new BorderRadius.circular(5.0),
                                            child: widget.preview.coverImage !=
                                                    null
                                                ? Image(
                                                    fit: BoxFit.fill,
                                                    image: MemoryImage(
                                                      widget.preview.coverImage,
                                                    ),
                                                  )
                                                : (html == null ||
                                                        globals.offline.val ||
                                                        widget.preview
                                                                .coverURL ==
                                                            null
                                                    ? Image(
                                                        fit: BoxFit.fill,
                                                        image: AssetImage(
                                                          'assets/images/blank.png',
                                                        ),
                                                      )
                                                    : FadeInImage.assetNetwork(
                                                        fadeInDuration:
                                                            Duration(
                                                          milliseconds: 250,
                                                        ),
                                                        fit: BoxFit.fill,
                                                        placeholder:
                                                            'assets/images/blank.png',
                                                        image: entry != null &&
                                                                entry.hdCoverURL !=
                                                                    null
                                                            ? entry.hdCoverURL
                                                            : widget.preview
                                                                .coverURL,
                                                      )),
                                          ),
                                        ),
                                      ),
                                      _makeInfo(),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(top: 3.0, bottom: 6.0),
                                    child: Text(
                                      entry.description.replaceAll(r'\n', '\n'),
                                      style: TextStyle(
                                        color: ColorTool.shade(
                                          HexColor(
                                            globals
                                                .theme.val['foreground_accent'],
                                          ),
                                          0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                  nextChapter != null
                                      ? Column(
                                          children: [
                                            Section.create(
                                                'Continue Reading: ' +
                                                    (nextChapter.started()
                                                        ? nextChapter
                                                            .percentReadString()
                                                        : '')),
                                            _makeChapterCard(nextChapter),
                                          ],
                                        )
                                      : null,
                                  Section.create(
                                    entry.chapters.isEmpty
                                        ? 'Chapters: None'
                                        : 'Chapters:',
                                  ),
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
