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
  String? _propertyServiceUrl;
  bool _isProgrammaticSelection = false;

  @override
  void initState() {
    super.initState();
    _initialiseGeoapify();
  }

  Future<void> _initialiseGeoapify() async {
    try {
      final apiKey = await AppConfig.loadGeoapifyApiKey();
      final host = await AppConfig.loadGeoapifyHost();
      final propertyServiceUrl = await AppConfig.loadPropertyServiceUrl();
      final service = GeoapifyService(apiKey: apiKey, host: host);

      if (!mounted) {
        service.dispose();
        return;
      }

      _geoapifyService?.dispose();
      setState(() {
        _geoapifyService = service;
        _propertyServiceUrl = propertyServiceUrl;
        _configError = null;
      });
    } on AppConfigException catch (error) {
      if (!mounted) return;
      _geoapifyService?.dispose();
      setState(() {
        _geoapifyService = null;
        _propertyServiceUrl = null;
        _configError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      _geoapifyService?.dispose();
      setState(() {
        _geoapifyService = null;
        _propertyServiceUrl = null;
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

    final configError = _configError;
    if (configError != null) {
      setState(() {
        _errorMessage = configError;
      });
      return;
    }

    final serviceUrl = _propertyServiceUrl?.trim();
    if (serviceUrl == null || serviceUrl.isEmpty) {
      setState(() {
        _errorMessage =
            'Property service URL not available. Check config.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _autocompleteError = null;
      _propertyAttributes = null;
      _propertyJson = null;
    });

    try {
      final response = await http.post(
        Uri.parse(serviceUrl),
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
              if (_propertyAttributes != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Property attributes',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: _PropertySummaryCard(
                    attributes: _propertyAttributes!,
                    address: _selectedAddress,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    title: const Text('View raw response'),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _propertyJson ??
                              const JsonEncoder.withIndent('  ')
                                  .convert(_propertyAttributes),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
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

class _PropertySummaryCard extends StatelessWidget {
  const _PropertySummaryCard({
    required this.attributes,
    this.address,
  });

  final Map<String, dynamic> attributes;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyType = _stringOrNull(attributes['property_type']);
    final council = _stringOrNull(attributes['council']);
    final estimatedValue = _numOrNull(attributes['estimated_value_aud']);
    final priceLower = _numOrNull(attributes['price_lower_bound']);
    final priceUpper = _numOrNull(attributes['price_upper_bound']);
    final bedrooms = _intOrNull(attributes['bedrooms']);
    final bathrooms = _intOrNull(attributes['bathrooms']);
    final carSpaces = _intOrNull(attributes['car_spaces']);
    final lotSize = _numOrNull(attributes['lot_size_m2']);
    final overlays = _stringList(attributes['overlays']);
    final schoolZones = _stringList(attributes['zoning_schools']);
    final internet = _stringOrNull(attributes['internet']);

    final metrics = <_PropertyMetricData>[
      if (propertyType != null)
        _PropertyMetricData(
          icon: Icons.home_work_outlined,
          value: propertyType,
          label: 'Property type',
        ),
      if (bedrooms != null)
        _PropertyMetricData(
          icon: Icons.bed_outlined,
          value: bedrooms.toString(),
          label: bedrooms == 1 ? 'Bedroom' : 'Bedrooms',
        ),
      if (bathrooms != null)
        _PropertyMetricData(
          icon: Icons.bathtub_outlined,
          value: bathrooms.toString(),
          label: bathrooms == 1 ? 'Bathroom' : 'Bathrooms',
        ),
      if (carSpaces != null)
        _PropertyMetricData(
          icon: Icons.directions_car_outlined,
          value: carSpaces.toString(),
          label: carSpaces == 1 ? 'Car space' : 'Car spaces',
        ),
      if (lotSize != null)
        _PropertyMetricData(
          icon: Icons.square_foot,
          value: _formatArea(lotSize),
          label: 'Land size',
        ),
    ];

    final estimatedValueText = _formatCurrency(estimatedValue);
    final priceGuideText = _formatPriceRange(priceLower, priceUpper);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address != null) ...[
            Text(
              address!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (council != null)
            Text(
              council,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (estimatedValueText != null || priceGuideText != null) ...[
            const SizedBox(height: 20),
            if (estimatedValueText != null) ...[
              Text(
                'Estimated value',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                estimatedValueText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (priceGuideText != null) ...[
              if (estimatedValueText != null) const SizedBox(height: 12),
              Text(
                'Price guide',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                priceGuideText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final metric in metrics) _PropertyMetricPill(metric: metric),
              ],
            ),
          ],
          if (overlays.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Planning overlays',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final overlay in overlays)
                  Chip(
                    avatar: const Icon(Icons.layers_outlined, size: 18),
                    label: Text(overlay),
                  ),
              ],
            ),
          ],
          if (schoolZones.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'School zones',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final zone in schoolZones)
                  Chip(
                    avatar: const Icon(Icons.school_outlined, size: 18),
                    label: Text(zone),
                  ),
              ],
            ),
          ],
          if (internet != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Internet: $internet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String? _formatCurrency(num? value) {
    if (value == null) return null;
    return '${String.fromCharCode(36)}${_formatNumber(value)}';
  }

  static String? _formatPriceRange(num? lower, num? upper) {
    if (lower == null && upper == null) return null;
    final formattedLower = lower != null ? _formatCurrency(lower) : null;
    final formattedUpper = upper != null ? _formatCurrency(upper) : null;

    if (formattedLower != null && formattedUpper != null) {
      return '$formattedLower – $formattedUpper';
    }
    return formattedLower ?? formattedUpper;
  }

  static String _formatArea(num value) {
    return '${_formatNumber(value)} m²';
  }

  static String _formatNumber(num value) {
    final precision = value is int || value % 1 == 0 ? 0 : 1;
    final numberString = value.toStringAsFixed(precision);
    final parts = numberString.split('.');
    final base = parts.first;
    final isNegative = base.startsWith('-');
    final integerPart = isNegative ? base.substring(1) : base;

    final buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      buffer.write(integerPart[i]);
      final remaining = integerPart.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    var decimalPart = '';
    if (parts.length > 1) {
      decimalPart = parts[1].replaceAll(RegExp(r'0+$'), '');
    }

    final formattedInteger = '${isNegative ? '-' : ''}${buffer.toString()}';
    return decimalPart.isNotEmpty
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;
  }

  static String? _stringOrNull(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static num? _numOrNull(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final parsedInt = int.tryParse(value);
      if (parsedInt != null) return parsedInt;
      return double.tryParse(value);
    }
    return null;
  }

  static int? _intOrNull(dynamic value) {
    final numeric = _numOrNull(value);
    return numeric?.round();
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class _PropertyMetricData {
  const _PropertyMetricData({
    required this.icon,
    required this.value,
    this.label,
  });

  final IconData icon;
  final String value;
  final String? label;
}

class _PropertyMetricPill extends StatelessWidget {
  const _PropertyMetricPill({required this.metric});

  final _PropertyMetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          metric.icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (metric.label != null) ...[
              const SizedBox(height: 2),
              Text(
                metric.label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }
}
