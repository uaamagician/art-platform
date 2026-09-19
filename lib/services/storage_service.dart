import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadPostImage({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final ref = _storage.ref().child('posts/$userId/${const Uuid().v4()}.$ext');

    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'heic': 'image/heic',
      'webp': 'image/webp',
      'gif': 'image/gif',
    };

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: mimeTypes[ext] ?? 'image/jpeg'),
    );

    return task.ref.getDownloadURL();
  }
}
