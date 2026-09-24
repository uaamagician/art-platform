import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class UploadedFile {
  final String url;
  final String path;

  const UploadedFile({required this.url, required this.path});
}

typedef UploadProgress = void Function(int transferred, int total);

class StorageService {
  final _storage = FirebaseStorage.instance;

  static const _imageMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
  };

  static String imageMimeType(String extension) =>
      _imageMimeTypes[extension.toLowerCase()] ?? 'image/jpeg';

  Future<UploadedFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    UploadProgress? onProgress,
  }) {
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    return _finish(ref, task, onProgress);
  }

  Future<UploadedFile> uploadFile({
    required String path,
    required File file,
    required String contentType,
    UploadProgress? onProgress,
  }) {
    final ref = _storage.ref(path);
    final task = ref.putFile(file, SettableMetadata(contentType: contentType));
    return _finish(ref, task, onProgress);
  }

  Future<UploadedFile> _finish(
    Reference ref,
    UploadTask task,
    UploadProgress? onProgress,
  ) async {
    final sub = task.snapshotEvents.listen(
      (s) => onProgress?.call(s.bytesTransferred, s.totalBytes),
      onError: (_) {},
    );
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return UploadedFile(url: await ref.getDownloadURL(), path: ref.fullPath);
  }

  Future<void> deleteQuietly(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }
}
