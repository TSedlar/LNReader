import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/util/ui/fonts.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/util/ui/themes.dart';

class SettingsView extends StatefulWidget {
  SettingsView({Key key}) : super(key: key);

  @override
  _SettingsView createState() => _SettingsView();
}

class _SettingsView extends State<SettingsView> {
  static String smallParagraph =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi sapien nulla, gravida quis tincidunt eu, vehicula eget eros. Duis semper lectus neque. Praesent porta facilisis tortor eu dapibus. Aenean mattis.';
  static String medParagraph =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi sapien nulla, gravida quis tincidunt eu, vehicula eget eros. Duis semper lectus neque.';
  static String lgParagraph =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi sapien nulla.';
  static String xlParagraph = 'Lorem ipsum dolor sit amet';
  static String sampleThemeParagraph =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed quis auctor libero, nec tristique felis. Aliquam lacus odio, euismod vitae iaculis nec, semper id erat.';

  String sampleParagraph = lgParagraph;

  @override
  void initState() {
    super.initState();
    globals.theme.bind(this);
    globals.readerFontFamily.bind(this);
    globals.readerFontSize.bind(this);
  }

  Widget _makeReaderTab() {
    return Padding(
      padding: EdgeInsets.only(left: 9.0, right: 9.0),
      child: GridView.count(
        shrinkWrap: true,
        primary: false,
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        children: Fonts.assetFonts
            .map((font) => GestureDetector(
                  onTap: () {
                    globals.readerFontFamily.val = font;
                  },
                  child: Card(
                    color: Theme.of(context).primaryColor,
                    child: Center(
                      child: Text(
                        font,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.headline.color,
                          fontFamily: font,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _makeReaderSies() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0, right: 12.0, top: 1.0),
          child: Row(
            children: [
              Expanded(
                child: MaterialButton(
                  child: Text(
                    'SMALL',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontFamily: globals.readerFontFamily.val,
                    ),
                  ),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).textTheme.headline.color,
                  onPressed: () {
                    sampleParagraph = smallParagraph;
                    globals.readerFontSize.val = 14.0;
                  },
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: MaterialButton(
                  child: Text(
                    'MED',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontFamily: globals.readerFontFamily.val,
                    ),
                  ),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).textTheme.headline.color,
                  onPressed: () {
                    sampleParagraph = medParagraph;
                    globals.readerFontSize.val = 18.0;
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MaterialButton(
                  child: Text(
                    'LG',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: globals.readerFontFamily.val,
                    ),
                  ),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).textTheme.headline.color,
                  onPressed: () {
                    sampleParagraph = lgParagraph;
                    globals.readerFontSize.val = 20.0;
                  },
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: MaterialButton(
                  child: Text(
                    'XL',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontFamily: globals.readerFontFamily.val,
                    ),
                  ),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).textTheme.headline.color,
                  onPressed: () {
                    sampleParagraph = xlParagraph;
                    globals.readerFontSize.val = 24.0;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _makeThemePreview(String cardTitle, [bool themePreview = true]) {
    Map<String, String> theme =
        themePreview ? Themes.listing[cardTitle] : globals.theme.val;
    TextStyle paragraphStyle = Theme.of(context)
        .textTheme
        .body1
        .copyWith(color: HexColor(theme['foreground']));
    if (!themePreview) {
      paragraphStyle = paragraphStyle.copyWith(
        fontFamily: globals.readerFontFamily.val,
        fontSize: globals.readerFontSize.val,
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 12.0,
          color: HexColor(
              themePreview ? theme['background_accent'] : theme['background']),
          child: Column(
            children: [
              cardTitle != null
                  ? SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Container(
                        color: HexColor(theme['background']),
                        child: Center(
                          child: Text(
                            cardTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headline
                                .copyWith(color: HexColor(theme['headings'])),
                          ),
                        ),
                      ),
                    )
                  : null,
              Padding(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 12.0,
                  bottom: themePreview ? 6.0 : 12.0,
                ),
                child: Card(
                  elevation: 0.0,
                  color: HexColor(theme['background']),
                  child: Padding(
                    padding: EdgeInsets.all(themePreview ? 12.0 : 0.0),
                    child: Text(
                      themePreview ? sampleThemeParagraph : sampleParagraph,
                      style: paragraphStyle,
                    ),
                  ),
                ),
              ),
              themePreview
                  ? Padding(
                      padding: EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 12.0),
                      child: new SizedBox(
                        width: double.infinity,
                        child: MaterialButton(
                          child: Text('Apply'),
                          onPressed: () {
                            globals.theme.val.addAll(theme);
                          },
                          color: HexColor(theme['background']),
                          textColor: HexColor(theme['headings']),
                        ),
                      ),
                    )
                  : null,
            ].where((child) => child != null).toList(),
          ),
        ),
      ),
    );
  }

  Widget _makeThemeTab() {
    final List<Widget> children = [
      SizedBox(height: 4.0),
    ];
    children.addAll(
      Themes.listing.keys.map((themeName) => _makeThemePreview(themeName)),
    );
    return ListView(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Settings', style: TextStyle(
            color: Theme.of(context).textTheme.title.color,
          )),
          bottom: TabBar(
            labelColor: Theme.of(context).textTheme.title.color,
            unselectedLabelColor: Theme.of(context).textTheme.body1.color,
            indicatorColor: Theme.of(context).textTheme.subhead.color,
            tabs: [
              Tab(text: 'Reader'),
              Tab(text: 'Theme'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              color: Theme.of(context).backgroundColor,
              child: SingleChildScrollView(
                child: new StickyHeader(
                  header: Container(
                    color: Theme.of(context).backgroundColor,
                    child: Column(children: [
                      _makeThemePreview(null, false),
                      _makeReaderSies(),
                    ]),
                  ),
                  content: _makeReaderTab(),
                ),
              ),
            ),
            Container(
              color: Theme.of(context).backgroundColor,
              child: _makeThemeTab(),
            ),
          ],
        ),
      ),
    );
  }
}
