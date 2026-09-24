import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/content_filter_service.dart';

void showContentFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: ContentFilterService.instance,
        builder: (context, _) {
          final filter = ContentFilterService.instance;
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '內容篩選',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('顯示成人內容（NSFW）'),
                  subtitle: const Text('預設隱藏'),
                  value: filter.showNsfw,
                  onChanged: filter.setShowNsfw,
                ),
                SwitchListTile(
                  title: const Text('顯示 AI 生成內容'),
                  value: filter.showAi,
                  onChanged: filter.setShowAi,
                ),
                if (AuthService().currentUser == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      '登入後設定會儲存到你的帳號',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
