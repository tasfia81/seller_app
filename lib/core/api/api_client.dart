import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../constants/app_config.dart';

/// A failed request, with the server's Bangla message ready to show.
class ApiException implements Exception {
  const ApiException(this.message, {this.code = 'error', this.status = 0, this.details = const {}});

  final String message;
  final String code;
  final int status;
  final Map<String, dynamic> details;

  bool get isUnauthorized => status == 401;

  /// Field-level issues from a 422 response: `{"payout.account_number": "…"}`.
  Map<String, String> get fieldIssues {
    final list = details['fields'];
    if (list is! List) return const {};
    return {
      for (final f in list)
        if (f is Map) '${f['field']}': '${f['issue']}',
    };
  }

  @override
  String toString() => 'ApiException($status, $code): $message';
}

/// Thin JSON client for the Street Sales API. Never pretends a request worked:
/// every failure becomes an [ApiException] with a message for the user.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        _base = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String _base;
  static const _timeout = Duration(seconds: 25);

  /// Set after login / sign-up; cleared on logout.
  String? token;

  /// Called when the server says the session is no longer valid.
  void Function()? onUnauthorized;

  Uri _uri(String path) {
    final uri = Uri.parse('$_base$path');
    if (kReleaseMode && uri.scheme != 'https') {
      throw const ApiException('সার্ভারের ঠিকানায় HTTPS ব্যবহার করতে হবে।');
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send(() => _http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _http.post(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body ?? const {}),
      ));

  /// Uploads one image as multipart `file` (type is read from the bytes).
  Future<dynamic> upload(String path, Uint8List bytes, {required String name}) {
    final (sub, ext) = imageType(bytes);
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: '$name.$ext', contentType: MediaType('image', sub)));
      return http.Response.fromStream(await _http.send(req));
    }, timeout: const Duration(seconds: 90));
  }

  Future<dynamic> _send(Future<http.Response> Function() request, {Duration timeout = _timeout}) async {
    final http.Response res;
    try {
      res = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('সার্ভার সময়মতো উত্তর দেয়নি। আবার চেষ্টা করুন।', code: 'timeout');
    } on SocketException {
      throw const ApiException('ইন্টারনেট সংযোগ নেই বা সার্ভারে পৌঁছানো যাচ্ছে না।', code: 'offline');
    } on http.ClientException {
      throw const ApiException('সার্ভারে পৌঁছানো যাচ্ছে না। একটু পরে চেষ্টা করুন।', code: 'offline');
    }

    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        data = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final err = data is Map && data['error'] is Map ? data['error'] as Map : const {};
    final ex = ApiException(
      '${err['message'] ?? 'কিছু একটা সমস্যা হয়েছে (${res.statusCode})। আবার চেষ্টা করুন।'}',
      code: '${err['code'] ?? 'http_${res.statusCode}'}',
      status: res.statusCode,
      details: err['details'] is Map ? Map<String, dynamic>.from(err['details'] as Map) : const {},
    );
    if (ex.isUnauthorized && token != null) onUnauthorized?.call();
    throw ex;
  }
}

/// (`jpeg` | `png` | `webp`, file extension) from the file's magic bytes.
(String, String) imageType(Uint8List b) {
  if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return ('png', 'png');
  if (b.length > 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return ('webp', 'webp');
  }
  return ('jpeg', 'jpg');
}
