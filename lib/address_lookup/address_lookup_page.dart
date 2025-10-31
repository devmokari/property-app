import 'package:flutter/material.dart';

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
  String? _errorMessage;
  String? _configError;

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

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matchedAddress = null;
        _errorMessage = 'Enter an address to search.';
      });
      return;
    }

    final service = _geoapifyService;
    if (service == null) {
      setState(() {
        _matchedAddress = null;
        _errorMessage =
            _configError ?? 'Geoapify API key not available. Check config.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _matchedAddress = null;
      _errorMessage = null;
    });

    try {
      final result = await service.lookup(query);
      if (!mounted) return;
      setState(() {
        if (result == null) {
          _errorMessage = 'No matches found for the provided address.';
          _matchedAddress = null;
        } else {
          _matchedAddress = result;
          _errorMessage = null;
        }
      });
    } on GeoapifyException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Address lookup failed: $error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _geoapifyService?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property App'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Address lookup',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _addressController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAddress(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Property address',
                  hintText: '123 Main St, Springfield',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchAddress,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Find address'),
              ),
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
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
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
            ],
          ),
        ),
      ),
    );
  }
}
