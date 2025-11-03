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
  static Map<String, dynamic>? _cachedConfig;

  static Future<Map<String, dynamic>> _loadConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final configString = await rootBundle.loadString(_configPath);
      final dynamic decoded = jsonDecode(configString);

      if (decoded is! Map) {
        throw const AppConfigException(
          'Invalid configuration format. Expected a JSON object.',
        );
      }

      final configMap =
          Map<String, dynamic>.from(decoded as Map<dynamic, dynamic>);
      _cachedConfig = configMap;
      return configMap;
    } on AppConfigException {
      rethrow;
    } catch (error) {
      throw AppConfigException('Failed to load configuration: $error');
    }
  }

  static Future<String> _loadStringValue(
    String key, {
    required String missingMessage,
  }) async {
    final config = await _loadConfig();
    final value = config[key];

    if (value is! String || value.trim().isEmpty) {
      throw AppConfigException(missingMessage);
    }

    return value.trim();
  }

  static Future<String> loadGeoapifyApiKey() async {
    return _loadStringValue(
      'geoapifyApiKey',
      missingMessage: 'Geoapify API key missing. Update assets/config.json.',
    );
  }

  static Future<String> loadGeoapifyHost() async {
    return _loadStringValue(
      'geoapifyHost',
      missingMessage: 'Geoapify API host missing. Update assets/config.json.',
    );
  }

  static Future<String> loadPropertyServiceUrl() async {
    return _loadStringValue(
      'propertyServiceUrl',
      missingMessage: 'Property service URL missing. Update assets/config.json.',
    );
  }
}
