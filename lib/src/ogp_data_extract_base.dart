// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:ogp_data_extract/utility/user_agent_client.dart';
import 'package:string_validator/string_validator.dart';

class UrlInfo {
  final int? contentLength;
  final String? contentType;
  final OgpData? ogpData;
  UrlInfo({
    this.contentLength,
    this.contentType,
    this.ogpData,
  });
}

class OgpDataExtract {
  /// returns [OgpData] from [url] and [userAgent].
  static Future<UrlInfo?> execute(String url,
      {String userAgent = 'bot'}) async {
    if (!isURL(url)) {
      return null;
    }

    final UserAgentClient client = UserAgentClient(userAgent, http.Client());
    final http.Response response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return null;
    }

    final Document? document = toDocument(response);

    final contentType = response.headers['content-type'];
    final contentLength =
        int.tryParse(response.headers['content-length'] ?? '');
    final ogpData = document != null ? OgpDataParser(document).parse() : null;

    return UrlInfo(
      contentLength: contentLength,
      contentType: contentType,
      ogpData: ogpData,
    );
  }

  /// returns [html.Document] from [http.Response].
  static Document? toDocument(http.Response response) {
    Document? document;
    try {
      document = parser.parse(utf8.decode(response.bodyBytes));
    } catch (err) {
      return null;
    }

    return document;
  }
}
