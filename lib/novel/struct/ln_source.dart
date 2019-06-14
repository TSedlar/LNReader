import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ln_reader/novel/ln_isolate.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/util/net/webview_reader.dart';
import 'package:ln_reader/util/observable.dart';
import 'package:ln_reader/util/ui/color_tool.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/util/ui/retry.dart';
import 'package:ln_reader/views/entry_view.dart';
import 'package:ln_reader/views/reader_view.dart';
import 'package:ln_reader/views/widget/loader.dart';

abstract class LNSource {
  // repectfully allow only web view if a site owner asks
  bool allowsReaderMode = true;

  // Supplied through abstraction
  String id;
  String name;
  String lang;
  String baseURL;
  String logoAsset;
  List<String> tabCategories;
  List<String> genres;

  // Set within the constructor
  ObservableValue<List<String>> selectedGenres;
  ObservableValue<List<LNPreview>> favorites;
  ObservableValue<List<LNPreview>> readPreviews;

  LNSource({
    this.id,
    this.name,
    this.lang,
    this.baseURL,
    this.logoAsset,
    this.tabCategories,
    this.genres,
  }) {
    this.selectedGenres = ObservableValue.fromList<String>(genres.toList());
    this.favorites = ObservableValue.fromList<LNPreview>([]);
    this.readPreviews = ObservableValue.fromList<LNPreview>([]);
  }

  Directory get dir => Directory(globals.appDir.val.path + '/$id/');

  String mkurl(String slug) {
    if (slug.startsWith('http')) {
      return slug;
    }
    if (slug.startsWith('/')) {
      slug = slug.substring(1);
    }
    return this.baseURL + slug;
  }

  String proxiedImage(String imgLink) {
    if (imgLink.contains('proxy?')) {
      return imgLink;
    }
    return 'https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&gadget=a&no_expand=1&resize_h=0&rewriteMime=image%2F*&url=$imgLink&imgmax=10000';
  }

  Future<String> readFromView(String url) => WebviewReader.read(url);

  List<Widget> makePreviewWidgets(
    BuildContext context,
    List<LNPreview> previews, {
    Function() onEntryTap,
    Function() onEntryNavPush,
    bool offline = true,
  }) {
    final double itemSize = 80;
    // (device_width - (cover_width + padding)) / (chip_width + chip_right_padding)
    final int maxChips =
        ((MediaQuery.of(context).size.width - 170.0) / 49.0).floor();
    return previews
        .map((preview) => GestureDetector(
              onTap: () async {
                if (offline && preview.entry == null) {
                  return;
                }

                if (onEntryTap != null) {
                  onEntryTap();
                }

                preview.loadExistingData();

                String html;

                if (!offline && preview.entry == null) {
                  html = await Retry.exec(
                    context,
                    () => preview.source.fetchEntry(preview),
                  );
                }

                Navigator.of(globals.homeContext.val).pushNamed(
                  '/entry',
                  arguments: EntryArgs(
                    preview: preview,
                    html: html,
                    usingCache: preview.entry != null,
                  ),
                );

                if (onEntryNavPush != null) {
                  Future.delayed(Duration(seconds: 2))
                      .then((_) => onEntryNavPush());
                }
              },
              child: Opacity(
                opacity: offline ? (preview.entry != null ? 1.0 : 0.5) : 1.0,
                child: Container(
                  margin: EdgeInsets.only(
                    left: 4.0,
                    top: 4.0,
                    bottom: 4.0,
                  ),
                  width: double.infinity,
                  height: itemSize,
                  decoration: new BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(itemSize / 2),
                      bottomLeft: Radius.circular(itemSize / 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 7.5, top: 5),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.all(Radius.circular(itemSize / 2)),
                          child: preview.coverImage != null
                              ? Image(
                                  width: itemSize - 10,
                                  height: itemSize - 10,
                                  fit: BoxFit.fill,
                                  image: MemoryImage(preview.coverImage),
                                )
                              : (offline
                                  ? Image(
                                      width: itemSize - 10,
                                      height: itemSize - 10,
                                      fit: BoxFit.fill,
                                      image:
                                          AssetImage('assets/images/blank.png'),
                                    )
                                  : FadeInImage.assetNetwork(
                                      width: itemSize - 10,
                                      height: itemSize - 10,
                                      fit: BoxFit.fill,
                                      fadeInDuration:
                                          Duration(milliseconds: 250),
                                      placeholder: 'assets/images/blank.png',
                                      image: preview.coverURL,
                                    )),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 6.0, top: 8.0),
                              child: Text(
                                preview.name,
                                overflow: TextOverflow.ellipsis,
                                textScaleFactor: 1.15,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .headline
                                        .color),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Row(
                                children: preview.genres
                                    .sublist(
                                        0, min(preview.genres.length, maxChips))
                                    .map((g) => Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Chip(
                                          backgroundColor: ColorTool.shade(
                                            Theme.of(context).backgroundColor,
                                            0.075,
                                          ),
                                          label: Container(
                                            constraints: BoxConstraints(
                                                minWidth: 45.0, maxWidth: 45.0),
                                            child: Center(
                                              child: Text(
                                                g,
                                                textScaleFactor: 0.65,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          labelStyle: Theme.of(context)
                                              .textTheme
                                              .body1
                                              .copyWith(
                                                color: HexColor(globals.theme
                                                    .val['foreground_accent']),
                                              ),
                                        )))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget makePreviewList(
    BuildContext context,
    List<LNPreview> previews, {
    Function() onEntryTap,
    Function() onEntryNavPush,
    bool offline = true,
  }) {
    final previewWidgets = makePreviewWidgets(
      context,
      previews,
      onEntryTap: onEntryTap,
      onEntryNavPush: onEntryNavPush,
      offline: offline,
    );
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) => previewWidgets[index],
              childCount: previews.length,
            ),
          )
        ],
      ),
    );
  }

  Future launchView({
    BuildContext context,
    LNPreview preview,
    LNChapter chapter,
    bool readerMode,
    bool offline = true,
  }) async {
    if (readerMode) {
      print('call: launchView');
      // Download if we're online and it's not downloaded
      if (!offline && !chapter.isDownloaded(preview)) {
        await chapter.download(context, preview);
      }

      String html = await preview.getChapterContent(chapter);

      bool selfCreated = chapter.isPDFDownloaded(preview);

      if (chapter.isDownloaded(preview)) {
        Loader.text.val = 'Creating readable content..';

        final readerContent =
            selfCreated ? html : await LNIsolate.makeReaderContent(this, html);

        Loader.text.val = 'Loading ReaderView!';

        Navigator.of(globals.homeContext.val).pushNamed(
          '/reader',
          arguments: ReaderArgs(
            chapter: chapter,
            html: readerContent,
          ),
        );

        await Future.delayed(Duration(seconds: 2));

        // forceGC();
        return Future.value(true);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).accentColor,
                title: Text(
                  'Failed...',
                  style: Theme.of(context).textTheme.subtitle,
                ),
                content: Text(
                  'There was an issue opening the chapter',
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
    } else {
      return WebviewReader.launchExternal(
        globals.homeContext.val,
        chapter.link,
      );
    }
  }

  Future<String> fetchPreviews();

  Map<String, List<LNPreview>> parsePreviews(String html);

  Future<String> search(String query, List<String> genre);

  List<LNPreview> parseSearchPreviews(String html);

  Future<String> fetchEntry(LNPreview preview);

  LNEntry parseEntry(LNSource source, String html);

  String makeReaderContent(String chapterHTML);

  Future<LNDownload> handleNonTextDownload(
    LNPreview preview,
    LNChapter chapter,
  );
}
