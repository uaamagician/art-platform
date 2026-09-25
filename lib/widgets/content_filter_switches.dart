import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/content_filter_service.dart';
import '../theme/app_theme.dart';

/// The two global switches: show adult content / show AI-generated content (both off by default).
class ContentFilterSwitches extends StatelessWidget {
  const ContentFilterSwitches({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentFilterService.instance,
      builder: (context, _) {
        final filter = ContentFilterService.instance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('顯示成人內容（NSFW）'),
              subtitle: const Text('預設隱藏'),
              value: filter.showNsfw,
              onChanged: filter.setShowNsfw,
            ),
            SwitchListTile(
              title: const Text('顯示 AI 生成內容'),
              subtitle: const Text('預設隱藏'),
              value: filter.showAi,
              onChanged: filter.setShowAi,
            ),
            if (AuthService().currentUser == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '登入後設定會儲存到你的帳號',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
