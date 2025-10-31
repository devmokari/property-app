import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfig {
  const AppConfig._();

  static const String _configPath = 'assets/config.json';

  static Future<String> loadGeoapifyApiKey() async {
    try {
      final configString = await rootBundle.loadString(_configPath);
      final Map<String, dynamic> jsonMap =
          jsonDecode(configString) as Map<String, dynamic>;
      final key = jsonMap['geoapifyApiKey'] as String?;

      if (key == null || key.trim().isEmpty) {
        throw const AppConfigException(
          'Geoapify API key missing. Update assets/config.json.',
        );
      }

      return key.trim();
    } on AppConfigException {
      rethrow;
    } catch (error) {
      throw AppConfigException('Failed to load configuration: $error');
    }
  }
}
