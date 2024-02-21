// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:ogp_data_extract/ogp_data_extract.dart';
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
    try {
      if (!isURL(url)) {
        return null;
      }

      // final UserAgentClient client = UserAgentClient(userAgent, http.Client());
      final Dio dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent': userAgent,
          },
          sendTimeout: const Duration(seconds: 2),
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      // final res = await dio.get(url, options: Options());
      // we only need headers
      var res = await dio.head(url);

      if (res.statusCode != 200) {
        return null;
      }

      final contentType = res.headers['content-type']?.firstOrNull;
      if (contentType != null && contentType.contains('text/html')) {
        res = await dio.get(url);
        if (res.statusCode != 200) {
          return null;
        }
      }

      final Document? document = toDocument(res);

      final contentLength =
          int.tryParse((res.headers['content-length']?.firstOrNull) ?? '');
      final ogpData = document != null ? OgpDataParser(document).parse() : null;

      return UrlInfo(
        contentLength: contentLength,
        contentType: contentType,
        ogpData: ogpData,
      );
    } catch (e) {
      debugPrint('OgpDataExtract.execute: $e');
      return null;
    }
  }

  /// returns [html.Document] from [http.Response].
  static Document? toDocument(Response response) {
    Document? document;
    try {
      document = parser.parse(response.data);
    } catch (err) {
      return null;
    }

    return document;
  }
}
