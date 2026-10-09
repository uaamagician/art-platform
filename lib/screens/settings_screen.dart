import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/disclaimer.dart';
import '../widgets/content_filter_switches.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登出？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('登出')),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService().signOut();
    if (context.mounted) Navigator.of(context).pop();
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _textCard(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(text, style: const TextStyle(height: 1.6, color: Color(0xFF5C544C))),
      );

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _section('內容設定'),
          const Card(child: ContentFilterSwitches()),
          if (user != null) ...[
            _section('帳號'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(user.email ?? '', style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _confirmSignOut(context),
                      child: const Text('登出'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _section('關於'),
          _textCard(aboutText),
          _section('委託免責聲明'),
          _textCard(commissionDisclaimer),
        ],
      ),
    );
  }
}
