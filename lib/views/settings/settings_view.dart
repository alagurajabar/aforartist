import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surface,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Settings coming soon...', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
