import 'dart:async';
import 'dart:isolate';

import 'package:http/http.dart';

class WebRequest {
  final String url;
  final Map<String, String> cookies;
  final SendPort source;

  WebRequest(this.url, this.cookies, this.source);
}

class WebResponse {
  final Map<String, String> headers;
  final String body;
  final int statusCode;

  WebResponse(this.headers, this.body, this.statusCode);
}

class DefaultNetClient extends BaseClient {
  final Client _inner;

  DefaultNetClient(this._inner);

  // Sends the request with default headers
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['scheme'] = 'https';
    request.headers['authority'] = request.url.host;
    request.headers['cache-control'] = 'max-age=0';
    request.headers['upgrade-insecure-requests'] = '1';
    request.headers['user-agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36';
    // request.headers['user-agent'] =
    //     'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.3 Safari/605.1.15';
    request.headers['accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3';
    request.headers['referer'] = request.url.origin;
    request.headers['accept-encoding'] = 'gzip, deflate';
    request.headers['accept-language'] = 'en-US,en;q=0.9';

    // print('making request with headers: ');
    // print(request.headers);

    return _inner.send(request);
  }
}

class NetReader {
  // Reads the given url page with optional cookies
  static Future<WebResponse> readPage(
    String url, {
    Map<String, String> cookies,
  }) =>
      _readPageIsolate(WebRequest(url, cookies, null));

  // Reads the given url page with optional cookies as an isolate
  static Future<WebResponse> readPageInBackground(
    String url, {
    Map<String, String> cookies,
  }) async {
    final sourcePort = ReceivePort();
    return Isolate.spawn(
      _readPageIsolate,
      WebRequest(url, cookies, sourcePort.sendPort),
    )
        .then((isolate) => sourcePort.first)
        .then((data) => WebResponse(data.headers, data.body, data.statusCode));
  }

  static Future<WebResponse> _readPageIsolate(WebRequest web) async {
    // Create client with default headers
    final client = DefaultNetClient(Client());

    // Setup headers
    final Map<String, String> headers = {};

    // Add cookies to headers
    _addCookies(headers, web.cookies);

    // Make request with headers
    return client.get(web.url, headers: headers).then((response) {
      // Conver body to sendable body
      String body = response.body; //String.fromCharCodes(response.bodyBytes);
      // Send response to SendPort if available
      if (web.source != null) {
        web.source
            .send(WebResponse(response.headers, body, response.statusCode));
      }
      // Return response
      return WebResponse(response.headers, body, response.statusCode);
    });
  }

  // Self explanatory -- adds cookies to given header
  static _addCookies(Map<String, String> headers, Map<String, String> cookies) {
    if (cookies != null) {
      headers['cookie'] =
          cookies.keys.map((name) => '$name=${cookies[name]}').join('; ') + ';';
    }
  }
}
