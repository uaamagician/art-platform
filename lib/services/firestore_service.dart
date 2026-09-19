import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 全專案共用的 Firestore 實例，指向實際存在的資料庫 "artdf"
/// (Firebase 專案裡沒有叫 "(default)" 的資料庫，所以不能用 FirebaseFirestore.instance)
FirebaseFirestore get appFirestore => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'artdf',
    );
