import 'firestore_service.dart';

class CategoryService {
  static List<String>? _cache;

  /// Category names in display order (cached for the session).
  Future<List<String>> names() async {
    final cached = _cache;
    if (cached != null) return cached;
    final snap = await appFirestore.collection('categories').orderBy('order').get();
    final list = snap.docs.map((d) => d.data()['name'] as String).toList();
    if (list.isNotEmpty) _cache = list;
    return list;
  }
}
