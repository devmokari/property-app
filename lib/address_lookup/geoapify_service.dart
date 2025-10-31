import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class GeoapifyException implements Exception {
  GeoapifyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeoapifyService {
  GeoapifyService({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  Future<String?> lookup(String query) async {
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/search', {
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
      _logNoMatch(query, responseBody);
      return null;
    }

    final firstFeature = features.first;
    if (firstFeature is! Map<String, dynamic>) {
      _logNoMatch(query, responseBody);
      return null;
    }

    final properties = firstFeature['properties'];
    if (properties is! Map<String, dynamic>) {
      _logNoMatch(query, responseBody);
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
      _logNoMatch(query, responseBody);
      return null;
    }

    return fallback;
  }

  void dispose() {
    _httpClient.close();
  }

  void _logNoMatch(String query, String responseBody) {
    developer.log(
      'Geoapify lookup returned no matches for query: $query. Response: $responseBody',
      name: 'GeoapifyService',
    );
  }
}
