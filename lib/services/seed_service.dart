import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 一次性寫入大分類與預設標籤，執行一次即可，不要重複執行。
class SeedService {
  static Future<void> seedCategoriesAndTags() async {
    final firestore = appFirestore;

    final categories = <String>[
      '傳統手繪',
      '顏料繪畫',
      '數位繪圖',
      '版畫印刷',
      '特殊技法',
    ];

    final mediumTags = <String>[
      '電繪', '數位插畫', '炭筆素描', '色鉛筆畫', '水彩畫', '油畫', '壓克力畫', '粉彩畫',
      '鉛筆素描', '鋼筆畫', '代針筆畫', '麥克筆畫', '水墨畫', '彩墨畫', '岩彩畫', '蛋彩畫',
      '膠彩畫', '蠟筆畫', '粉蠟筆畫', '針筆點繪', '木刻版畫', '銅版畫', '石版畫', '絲網印刷畫',
      '美柔汀版畫', '濕壁畫', '乾壁畫', '流體畫', '酒精墨水畫', '馬賽克鑲嵌畫', '噴槍畫', '烙畫',
      '刮畫', '沙畫', '玻璃彩繪', '琺瑯彩繪', '向量繪圖', '3D數位雕刻', '像素畫', '粉筆畫',
      '原子筆畫', '硃砂畫', '色粉畫', '炭精筆畫', '指甲油畫', '噴漆畫',
    ];

    final batch = firestore.batch();

    for (var i = 0; i < categories.length; i++) {
      final ref = firestore.collection('categories').doc();
      batch.set(ref, {
        'name': categories[i],
        'order': i,
      });
    }

    for (final tag in mediumTags) {
      final ref = firestore.collection('tags').doc(tag);
      batch.set(ref, {
        'name': tag,
        'usageCount': 0,
        'type': 'medium',
      });
    }

    await batch.commit();
  }
}
