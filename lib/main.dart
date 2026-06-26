import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/debug/ble_debug_screen.dart';

void main() {
  // Logs BLE plus discrets (mettre LogLevel.verbose pour tout voir).
  FlutterBluePlus.setLogLevel(LogLevel.warning, color: false);
  runApp(const ProviderScope(child: AyurDebugApp()));
}

class AyurDebugApp extends StatelessWidget {
  const AyurDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayur Life — Debug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B9AAA),
        useMaterial3: true,
      ),
      home: const BleDebugScreen(),
    );
  }
}
