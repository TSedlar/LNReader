import 'package:flutter/material.dart';
import 'package:ln_reader/util/net/webview_reader.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;

class AboutView extends StatelessWidget {
  final Map<String, String> dependencies = {
    'path_provider ^1.1.0': 'https://pub.dev/packages/path_provider',
    'esys_flutter_share ^1.0.2': 'https://pub.dev/packages/esys_flutter_share',
    'url_launcher ^5.0.2': 'https://pub.dev/packages/url_launcher',
    'intl ^0.15.8': 'https://pub.dev/packages/intl',
    'http ^0.12.0+2': 'https://pub.dev/packages/http',
    'html ^0.14.0': 'https://pub.dev/packages/html',
    'connectivity ^0.4.3+2': 'https://pub.dev/packages/connectivity',
    'interactive_webview ^0.1.1+8':
        'https://pub.dev/packages/interactive_webview',
    'shared_preferences ^0.5.3+1':
        'https://pub.dev/packages/shared_preferences',
    'battery_indicator ^0.0.2': 'https://pub.dev/packages/battery_indicator',
    'sticky_headers ^0.1.8': 'https://pub.dev/packages/sticky_headers',
    'flutter_speed_dial ^1.1.2': 'https://pub.dev/packages/flutter_speed_dial',
  };

  final githubURL = 'https://github.com/TSedlar/LNReader';

  Widget _makeExpandCard({
    BuildContext context,
    String title,
    List<Widget> children,
  }) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.headline.color),
        ),
        children: children,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  _txt(String text, {double bottomPadding = 4.0}) {
    return Padding(
      padding: EdgeInsets.only(
          left: 12.0, right: 12.0, top: 4.0, bottom: bottomPadding),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: HexColor(globals.theme.val['headings']),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).backgroundColor;
    final TextStyle fg = Theme.of(context).textTheme.subhead;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('About', style: Theme.of(context).textTheme.headline),
        iconTheme: IconThemeData(color: fg.color),
      ),
      body: ListView(
        children: [
          // Dependencies
          _makeExpandCard(
              context: context,
              title: 'Dependencies',
              children: dependencies.keys
                  .map((key) => ListTile(
                        title: Text(key, style: fg),
                        trailing: IconButton(
                          padding: EdgeInsets.only(
                            left: 24.0,
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          icon: Icon(Icons.launch, color: fg.color),
                          onPressed: () => WebviewReader.launchExternal(
                                context,
                                dependencies[key],
                              ),
                        ),
                      ))
                  .toList()),
          // Copyright Notice
          _makeExpandCard(
            context: context,
            title: 'Copyright Notice',
            children: [
              _txt(
                'LNReader is a website viewer as a mobile application. The content it displays is from 3rd party aggregation services for reading novels. The content that is searched within this app is not provided nor produced by LNReader.',
              ),
              _txt(
                'Copyright of all contents belong to the authors/publishers of the 3rd party aggregation services. If there are any questions, please contact us and we will give you the contact information of the 3rd party aggregation service in question.',
              ),
              _txt(
                'Contents of the novels represent the author personally and do not represent LNReader. Please report to us if any content violates the law. We do not bear legal responsibility for the content automatically provided by 3rd party aggregation services.',
              ),
              _txt(
                'Contact: LNReader@sedlar.me',
                bottomPadding: 10.0,
              ),
            ],
          ),
          // Aggregators
          _makeExpandCard(
              context: context,
              title: '3rd Party Aggregators',
              children: globals.sources.keys
                  .map((key) => Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: ListTile(
                          title: Text(globals.sources[key].name, style: fg),
                          leading: Image(
                            image: AssetImage(globals.sources[key].logoAsset),
                          ),
                          trailing: IconButton(
                            padding: EdgeInsets.only(
                              left: 24.0,
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            icon: Icon(Icons.launch, color: fg.color),
                            onPressed: () => WebviewReader.launchExternal(
                                  context,
                                  globals.sources[key].baseURL,
                                ),
                          ),
                        ),
                      ))
                  .toList()),
          // GitHub
          Container(
            color: Theme.of(context).primaryColor,
            child: ListTile(
              title: Text('GitHub', style: fg),
              trailing: IconButton(
                padding: EdgeInsets.only(left: 24.0, top: 8.0, bottom: 8.0),
                icon: Icon(Icons.launch, color: fg.color),
                onPressed: () =>
                    WebviewReader.launchExternal(context, githubURL),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
