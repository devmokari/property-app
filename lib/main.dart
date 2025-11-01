import 'package:flutter/material.dart';

import 'address_lookup/address_lookup_page.dart';

void main() {
  runApp(const HomegptApp());
}

class HomegptApp extends StatelessWidget {
  const HomegptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeGPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AddressLookupPage(),
    );
  }
}
