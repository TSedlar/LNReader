import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ln_reader/novel/ln_isolate.dart';
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
  }) {
    final double itemSize = 80;
    // (device_width - (cover_width + padding)) / (chip_width + chip_right_padding)
    final int maxChips =
        ((MediaQuery.of(context).size.width - 170.0) / 49.0).floor();
    return previews
        .map((preview) => GestureDetector(
              onTap: () async {
                if (onEntryTap != null) {
                  onEntryTap();
                }

                preview.loadExistingData();

                final html = await preview.source.fetchEntry(preview);

                if (html != null) {
                  Navigator.of(globals.homeContext.val).pushNamed(
                    '/entry',
                    arguments: EntryArgs(
                      preview: preview,
                      html: html,
                    ),
                  );
                  if (onEntryNavPush != null) {
                    Future.delayed(Duration(seconds: 2))
                        .then((_) => onEntryNavPush());
                  }
                } else {
                  print('A good connection is needed for LNReader..');
                }
              },
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
                        child: FadeInImage.assetNetwork(
                          width: itemSize - 10,
                          height: itemSize - 10,
                          fadeInDuration: Duration(milliseconds: 250),
                          placeholder: 'assets/images/blank.png',
                          image: preview.coverURL,
                          fit: BoxFit.fill,
                        ),
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
            ))
        .toList();
  }

  Widget makePreviewList(
    BuildContext context,
    List<LNPreview> previews, {
    Function() onEntryTap,
    Function() onEntryNavPush,
  }) {
    final previewWidgets = makePreviewWidgets(
      context,
      previews,
      onEntryTap: onEntryTap,
      onEntryNavPush: onEntryNavPush,
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

  Future launchView(
    BuildContext context,
    LNChapter chapter,
    bool readerMode,
  ) async {
    if (readerMode && chapter.isTextFormat()) {
      final html = await Retry.exec(context, () {
        return readFromView(chapter.link);
      });

      if (html != null) {
        Loader.text.val = 'Creating readable content..';

        final content = await LNIsolate.makeReaderContent(this, html);

        Loader.text.val = 'Loading ReaderView!';

        Navigator.of(globals.homeContext.val).pushNamed(
          '/reader',
          arguments: ReaderArgs(chapter: chapter, content: content),
        );

        return Future.value(true);
      } else {
        print('Failed to open chapter, nav#pop?');
        return Future.value(false);
      }
    } else {
      return WebviewReader.launchExternal(globals.homeContext.val, chapter.link);
    }
  }

  Future<String> fetchPreviews();

  Map<String, List<LNPreview>> parsePreviews(String html);

  Future<String> search(String query, List<String> genre);

  List<LNPreview> parseSearchPreviews(String html);

  Future<String> fetchEntry(LNPreview preview);

  LNEntry parseEntry(LNSource source, String html);

  String makeReaderContent(String chapterHTML);
}
