import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'geoapify_service.dart';

class AddressLookupPage extends StatefulWidget {
  const AddressLookupPage({super.key});

  @override
  State<AddressLookupPage> createState() => _AddressLookupPageState();
}

class _AddressLookupPageState extends State<AddressLookupPage> {
  final TextEditingController _addressController = TextEditingController();
  GeoapifyService? _geoapifyService;
  bool _isLoading = false;
  String? _matchedAddress;
  String? _selectedAddress;
  String? _errorMessage;
  String? _configError;
  Timer? _debounce;
  bool _isAutocompleteLoading = false;
  String? _autocompleteError;
  List<String> _suggestions = const [];
  String _latestAutocompleteQuery = '';
  Map<String, dynamic>? _propertyAttributes;
  String? _propertyJson;
  bool _isProgrammaticSelection = false;

  @override
  void initState() {
    super.initState();
    _initialiseGeoapify();
  }

  Future<void> _initialiseGeoapify() async {
    try {
      final apiKey = await AppConfig.loadGeoapifyApiKey();
      if (!mounted) return;
      setState(() {
        _geoapifyService = GeoapifyService(apiKey: apiKey);
        _configError = null;
      });
    } on AppConfigException catch (error) {
      if (!mounted) return;
      setState(() {
        _configError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _configError = 'Failed to load configuration: $error';
      });
    }
  }

  Future<void> _fetchPropertyAttributes() async {
    final address = _selectedAddress?.trim();
    if (address == null || address.isEmpty) {
      setState(() {
        _errorMessage = 'Select an address before searching.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _matchedAddress = null;
      _errorMessage = null;
      _autocompleteError = null;
      _propertyAttributes = null;
      _propertyJson = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://g7eku3ruwr6e2hduscxavmi6zy0wsiel.lambda-url.ap-southeast-2.on.aws/'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'getProperty',
          'address': address,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _matchedAddress = address;
            _propertyAttributes = decoded;
            _propertyJson = const JsonEncoder.withIndent('  ').convert(decoded);
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format from property service.';
          });
        }
      } else {
        final message = _parseErrorMessage(response.body);
        setState(() {
          _errorMessage =
              'Failed to retrieve property details: ${response.statusCode} $message';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to retrieve property details: $error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Ignore parsing errors and fall back to raw body.
    }
    return responseBody;
  }

  @override
  void dispose() {
    _geoapifyService?.dispose();
    _debounce?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    if (_isProgrammaticSelection) {
      _isProgrammaticSelection = false;
      return;
    }

    _debounce?.cancel();

    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _autocompleteError = null;
        _isAutocompleteLoading = false;
        _latestAutocompleteQuery = query;
        _selectedAddress = null;
        _matchedAddress = null;
        _propertyAttributes = null;
        _propertyJson = null;
        _errorMessage = null;
      });
      return;
    }

    final service = _geoapifyService;
    if (service == null) {
      setState(() {
        _suggestions = const [];
        _isAutocompleteLoading = false;
        _autocompleteError =
            _configError ?? 'Geoapify API key not available. Check config.';
        _latestAutocompleteQuery = query;
        _selectedAddress = null;
        _matchedAddress = null;
        _propertyAttributes = null;
        _propertyJson = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isAutocompleteLoading = true;
      _autocompleteError = null;
      _latestAutocompleteQuery = query;
      _selectedAddress = null;
      _matchedAddress = null;
      _propertyAttributes = null;
      _propertyJson = null;
      _errorMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final suggestions = await service.autocomplete(query);
        if (!mounted || query != _latestAutocompleteQuery) {
          return;
        }
        setState(() {
          _suggestions = suggestions;
          _autocompleteError = null;
        });
      } on GeoapifyException catch (error) {
        if (!mounted || query != _latestAutocompleteQuery) {
          return;
        }
        setState(() {
          _suggestions = const [];
          _autocompleteError = error.message;
        });
      } catch (error) {
        if (!mounted || query != _latestAutocompleteQuery) {
          return;
        }
        setState(() {
          _suggestions = const [];
          _autocompleteError = 'Failed to fetch address suggestions: $error';
        });
      } finally {
        if (!mounted || query != _latestAutocompleteQuery) {
          return;
        }
        setState(() {
          _isAutocompleteLoading = false;
        });
      }
    });
  }

  Future<void> _onSuggestionSelected(String suggestion) async {
    _isProgrammaticSelection = true;
    _addressController.text = suggestion;
    _addressController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );

    setState(() {
      _suggestions = const [];
      _autocompleteError = null;
      _latestAutocompleteQuery = suggestion;
      _selectedAddress = suggestion;
      _matchedAddress = null;
      _propertyAttributes = null;
      _propertyJson = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/icon.png'),
          ),
        ),
        title: const Text('HomeGPT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find your next home',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search for property addresses and confirm the perfect location for your clients or listings.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Address lookup',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _addressController,
                textInputAction: TextInputAction.done,
                onChanged: _onAddressChanged,
                decoration: InputDecoration(
                  labelText: 'Property address',
                  hintText: '123 Main St, Springfield',
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _selectedAddress != null
                              ? _fetchPropertyAttributes
                              : null,
                          tooltip: 'Search property',
                        ),
                ),
              ),
              if (_isAutocompleteLoading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  minHeight: 3,
                  color: theme.colorScheme.primary,
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.6),
                ),
              ],
              if (_autocompleteError != null && _configError == null) ...[
                const SizedBox(height: 12),
                Text(
                  _autocompleteError!,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ],
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      for (final suggestion in _suggestions)
                        ListTile(
                          leading: Icon(
                            Icons.place_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(suggestion),
                          onTap: () => _onSuggestionSelected(suggestion),
                        ),
                    ],
                  ),
                ),
              ],
              if (_configError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _configError!,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ],
              if (_errorMessage != null && _configError == null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ],
              if (_matchedAddress != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Matched address',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _matchedAddress!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
              if (_propertyAttributes != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Property attributes',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        _propertyJson ??
                            const JsonEncoder.withIndent('  ')
                                .convert(_propertyAttributes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
