import 'dart:convert';
import 'package:http/http.dart' as http;

import 'log_utils.dart';

class GeoapifyException implements Exception {
  GeoapifyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeoapifyService {
  GeoapifyService({
    required this.apiKey,
    required this.host,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final String host;
  final http.Client _httpClient;

  Future<List<String>> autocomplete(String query) async {
    final uri = Uri.https(host, '/v1/geocode/autocomplete', {
      'text': query,
      'limit': '5',
      'apiKey': apiKey,
    });

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw GeoapifyException(
        'Address suggestions unavailable (${response.statusCode}). Try again later.',
      );
    }

    final Map<String, dynamic> jsonMap =
        jsonDecode(response.body) as Map<String, dynamic>;
    final features = jsonMap['features'];
    if (features is! List || features.isEmpty) {
      return const [];
    }

    final suggestions = <String>{};
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) {
        continue;
      }

      final properties = feature['properties'];
      if (properties is! Map<String, dynamic>) {
        continue;
      }

      final formatted = (properties['formatted'] as String?)?.trim();
      if (formatted != null && formatted.isNotEmpty) {
        suggestions.add(formatted);
        continue;
      }

      final fallback = [properties['address_line1'], properties['address_line2']]
          .whereType<String>()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .join(', ');

      if (fallback.isNotEmpty) {
        suggestions.add(fallback);
      }
    }

    return suggestions.toList(growable: false);
  }

  Future<String?> lookup(String query) async {
    final uri = Uri.https(host, '/v1/geocode/search', {
      'text': query,
      'format': 'json',
      'apiKey': apiKey,
    });

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw GeoapifyException(
        'Address lookup failed (${response.statusCode}). Try again later.',
      );
    }

    final responseBody = response.body;
    final Map<String, dynamic> jsonMap =
        jsonDecode(responseBody) as Map<String, dynamic>;
    final features = jsonMap['features'];
    if (features is! List || features.isEmpty) {
      await logGeoapifyNoMatch(query, uri, responseBody);
      return null;
    }

    final firstFeature = features.first;
    if (firstFeature is! Map<String, dynamic>) {
      await logGeoapifyNoMatch(query, uri, responseBody);
      return null;
    }

    final properties = firstFeature['properties'];
    if (properties is! Map<String, dynamic>) {
      await logGeoapifyNoMatch(query, uri, responseBody);
      return null;
    }

    final formatted = (properties['formatted'] as String?)?.trim();
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }

    final fallback = [properties['address_line1'], properties['address_line2']]
        .whereType<String>()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(', ');

    if (fallback.isEmpty) {
      await logGeoapifyNoMatch(query, uri, responseBody);
      return null;
    }

    return fallback;
  }

  void dispose() {
    _httpClient.close();
  }

}
