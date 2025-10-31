import 'dart:convert';

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

    final Map<String, dynamic> jsonMap =
        jsonDecode(response.body) as Map<String, dynamic>;
    final features = jsonMap['features'];
    if (features is! List || features.isEmpty) {
      return null;
    }

    final firstFeature = features.first;
    if (firstFeature is! Map<String, dynamic>) {
      return null;
    }

    final properties = firstFeature['properties'];
    if (properties is! Map<String, dynamic>) {
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

    return fallback.isEmpty ? null : fallback;
  }

  void dispose() {
    _httpClient.close();
  }
}
