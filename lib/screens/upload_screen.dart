import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../utils/tag_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/auth_guard.dart';

class _PickedImage {
  final String name;
  final Uint8List bytes;

  const _PickedImage(this.name, this.bytes);

  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
}

class _PickedAttachment {
  final PlatformFile file;
  final int size;

  const _PickedAttachment(this.file, this.size);
}

/// Pops with `true` when the post was published.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const _maxImages = 10;
  static const _maxImageBytes = 20 * 1024 * 1024;
  static const _maxAttachments = 5;
  static const _maxAttachmentBytes = 100 * 1024 * 1024;
  static const _maxTags = 10;
  static const _collapsedPresetCount = 12;
  static const _imageExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customTagController = TextEditingController();

  final List<_PickedImage> _images = [];
  final List<_PickedAttachment> _attachments = [];
  final Set<String> _presetTags = {};
  final List<String> _customTags = [];

  late final Future<List<String>> _categoriesFuture;
  late final Future<List<String>> _presetTagsFuture;
  List<String> _presetTagNames = [];

  String? _category;
  bool? _isNsfw;
  bool? _isAiGenerated;
  bool _labelError = false;
  bool _showAllPresets = false;

  bool _submitting = false;
  double _progress = 0;
  String _status = '';

  int get _tagCount => _presetTags.length + _customTags.length;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
    _presetTagsFuture = _loadPresetTags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _images.isEmpty) _showImageSourceSheet();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadCategories() async {
    final snap = await appFirestore.collection('categories').orderBy('order').get();
    return snap.docs.map((d) => d.data()['name'] as String).toList();
  }

  Future<List<String>> _loadPresetTags() async {
    final snap = await appFirestore
        .collection('tags')
        .where('type', isEqualTo: 'medium')
        .get();
    final names = snap.docs.map((d) => d.data()['name'] as String).toList()..sort();
    _presetTagNames = names;
    return names;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- picking -------------------------------------------------------------

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('從相簿選擇（可多選）'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              title: const Text('從檔案選擇'),
              subtitle: const Text('JPG、PNG、WebP、GIF、BMP、HEIC'),
              onTap: () {
                Navigator.pop(context);
                _pickFromFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  int get _remainingImageSlots => _maxImages - _images.length;

  void _addImage(String name, Uint8List bytes) {
    if (bytes.length > _maxImageBytes) {
      _showMessage('$name 超過 ${_maxImageBytes ~/ (1024 * 1024)}MB，已略過');
      return;
    }
    _images.add(_PickedImage(name, bytes));
  }

  Future<void> _pickFromGallery() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('最多只能上傳 $_maxImages 張圖片');
      return;
    }
    try {
      final picker = ImagePicker();
      final List<XFile> files;
      if (_remainingImageSlots == 1) {
        final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
        files = file == null ? [] : [file];
      } else {
        files = await picker.pickMultiImage(
          imageQuality: 90,
          limit: _remainingImageSlots,
        );
      }
      for (final file in files.take(_remainingImageSlots)) {
        _addImage(file.name, await file.readAsBytes());
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showMessage('無法取得圖片，請確認已允許存取相簿');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('最多只能上傳 $_maxImages 張圖片');
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (file == null) return;
      _addImage(file.name, await file.readAsBytes());
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showMessage('無法開啟相機，請確認已允許使用相機');
    }
  }

  Future<void> _pickFromFiles() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('最多只能上傳 $_maxImages 張圖片');
      return;
    }
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _imageExtensions,
      );
      for (final file in files.take(_remainingImageSlots)) {
        _addImage(file.name, await file.readAsBytes());
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showMessage('無法讀取檔案');
    }
  }

  Future<void> _pickAttachments() async {
    if (_attachments.length >= _maxAttachments) {
      _showMessage('最多只能附加 $_maxAttachments 個檔案');
      return;
    }
    try {
      final files = await FilePicker.pickFiles();
      for (final file in files) {
        if (_attachments.length >= _maxAttachments) break;
        final size = file.lengthSync() ?? await file.length() ?? 0;
        if (size > _maxAttachmentBytes) {
          _showMessage('${file.name} 超過 ${_maxAttachmentBytes ~/ (1024 * 1024)}MB，已略過');
          continue;
        }
        _attachments.add(_PickedAttachment(file, size));
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showMessage('無法讀取檔案');
    }
  }

  // ---- tags ----------------------------------------------------------------

  void _togglePreset(String name, bool selected) {
    if (selected && _tagCount >= _maxTags && !_presetTags.contains(name)) {
      _showMessage('最多只能加入 $_maxTags 個標籤');
      return;
    }
    setState(() {
      selected ? _presetTags.add(name) : _presetTags.remove(name);
    });
  }

  void _addCustomTag() {
    final tag = normalizeTag(_customTagController.text);
    _customTagController.clear();
    if (tag.isEmpty) return;

    final preset = _presetTagNames.where((p) => normalizeTag(p) == tag).firstOrNull;
    if (preset != null) {
      _togglePreset(preset, true);
      return;
    }
    if (_customTags.contains(tag)) return;
    if (_tagCount >= _maxTags) {
      _showMessage('最多只能加入 $_maxTags 個標籤');
      return;
    }
    setState(() => _customTags.add(tag));
  }

  // ---- submit --------------------------------------------------------------

  String _safeFileName(String name) => name.replaceAll(RegExp(r'[^\w.\-]'), '_');

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    if (_images.isEmpty) return _showMessage('請至少選擇一張圖片');
    if (title.isEmpty) return _showMessage('請輸入標題');
    if (_category == null) return _showMessage('請選擇分類');
    if (_isNsfw == null || _isAiGenerated == null) {
      setState(() => _labelError = true);
      return _showMessage('請回答成人內容與 AI 生成兩項標籤');
    }

    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    final images = List<_PickedImage>.of(_images);
    final attachments = List<_PickedAttachment>.of(_attachments);
    final totalBytes = images.fold<int>(0, (sum, i) => sum + i.bytes.length) +
        attachments.fold<int>(0, (sum, a) => sum + a.size);
    final transferred = List<int>.filled(images.length + attachments.length, 0);

    void report(int index, int done) {
      transferred[index] = done;
      if (!mounted || totalBytes == 0) return;
      final total = transferred.fold<int>(0, (sum, v) => sum + v);
      setState(() => _progress = (total / totalBytes).clamp(0.0, 0.98).toDouble());
    }

    setState(() {
      _submitting = true;
      _progress = 0;
      _status = '上傳中';
    });

    final storage = StorageService();
    final postService = PostService();
    final postRef = postService.newPostRef();
    final uploadedPaths = <String>[];

    try {
      double? aspectRatio;
      try {
        final codec = await ui.instantiateImageCodec(images.first.bytes, targetWidth: 200);
        final frame = await codec.getNextFrame();
        if (frame.image.height > 0) {
          aspectRatio = frame.image.width / frame.image.height;
        }
        frame.image.dispose();
        codec.dispose();
      } catch (_) {}

      final imageUploads = <Future<String>>[
        for (var i = 0; i < images.length; i++)
          storage
              .uploadBytes(
                path: 'posts/${user.uid}/${postRef.id}/$i.${images[i].extension}',
                bytes: images[i].bytes,
                contentType: StorageService.imageMimeType(images[i].extension),
                onProgress: (done, _) => report(i, done),
              )
              .then((file) {
            uploadedPaths.add(file.path);
            return file.url;
          }),
      ];

      final attachmentUploads = <Future<PostAttachment>>[
        for (var i = 0; i < attachments.length; i++)
          () async {
            final picked = attachments[i];
            final path =
                'attachments/${user.uid}/${postRef.id}/${i}_${_safeFileName(picked.file.name)}';
            final localPath = picked.file.path;
            final uploaded = localPath != null
                ? await storage.uploadFile(
                    path: path,
                    file: File(localPath),
                    contentType: 'application/octet-stream',
                    onProgress: (done, _) => report(images.length + i, done),
                  )
                : await storage.uploadBytes(
                    path: path,
                    bytes: await picked.file.readAsBytes(),
                    contentType: 'application/octet-stream',
                    onProgress: (done, _) => report(images.length + i, done),
                  );
            uploadedPaths.add(uploaded.path);
            return PostAttachment(
              name: picked.file.name,
              url: uploaded.url,
              size: picked.size,
            );
          }(),
      ];

      final imageUrls = await Future.wait(imageUploads);
      final uploadedAttachments = await Future.wait(attachmentUploads);

      if (mounted) setState(() => _status = '發布中');
      final post = Post(
        id: postRef.id,
        userId: user.uid,
        userName: user.displayName ?? '',
        userPhotoUrl: user.photoURL ?? '',
        title: title,
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        attachments: uploadedAttachments,
        category: _category!,
        tags: [..._presetTags, ..._customTags],
        isNsfw: _isNsfw!,
        isAiGenerated: _isAiGenerated!,
        likesCount: 0,
        commentsCount: 0,
        aspectRatio: aspectRatio,
        createdAt: null,
      );
      await postService.publish(
        ref: postRef,
        post: post,
        presetTags: _presetTagNames.toSet(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      await Future.wait(uploadedPaths.map(storage.deleteQuietly));
      if (mounted) _showMessage('發布失敗，請確認網路後再試一次');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發布作品'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('發布'),
          ),
        ],
        bottom: _submitting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (_submitting)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$_status ${(_progress * 100).round()}%，請不要離開此頁面',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            _sectionTitle('作品圖片（${_images.length}/$_maxImages）', '第一張為封面'),
            _buildImageStrip(),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(labelText: '標題'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: '作品描述（選填）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('分類', null),
            _buildCategoryPicker(),
            const SizedBox(height: 24),
            _sectionTitle('標籤（$_tagCount/$_maxTags）', '可選媒材標籤，也能自訂'),
            _buildTagPicker(),
            const SizedBox(height: 24),
            _sectionTitle('圖層檔／附件（選填）', 'PSD、CLIP、KRA、Procreate…單檔上限 100MB'),
            _buildAttachments(),
            const SizedBox(height: 24),
            _buildSafetyLabels(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String? hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hint,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageStrip() {
    return SizedBox(
      height: 146,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _images.length; i++) _buildImageTile(i),
          if (_images.length < _maxImages)
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('新增圖片'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final image = _images[index];
    const smallButton = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, 28)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    );

    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  image.bytes,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 104,
                    height: 104,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Text(image.extension.toUpperCase()),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '封面',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              index > 0
                  ? TextButton(
                      style: smallButton,
                      onPressed: () => setState(() => _images.insert(0, _images.removeAt(index))),
                      child: const Text('設封面'),
                    )
                  : const SizedBox.shrink(),
              TextButton(
                style: smallButton,
                onPressed: () => setState(() => _images.removeAt(index)),
                child: const Text('移除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return FutureBuilder<List<String>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('分類載入失敗，請確認網路連線');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final name in snapshot.data!)
              ChoiceChip(
                label: Text(name),
                showCheckmark: false,
                selected: _category == name,
                onSelected: (_) => setState(() => _category = name),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTagPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<String>>(
          future: _presetTagsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? const Text('標籤載入失敗，仍可自訂標籤')
                  : const LinearProgressIndicator();
            }
            final names = snapshot.data!;
            final visible = _showAllPresets
                ? names
                : names.take(_collapsedPresetCount).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in visible)
                      FilterChip(
                        label: Text(name),
                        showCheckmark: false,
                        selected: _presetTags.contains(name),
                        onSelected: (selected) => _togglePreset(name, selected),
                      ),
                  ],
                ),
                if (names.length > _collapsedPresetCount)
                  TextButton(
                    onPressed: () => setState(() => _showAllPresets = !_showAllPresets),
                    child: Text(_showAllPresets ? '收合' : '顯示全部 ${names.length} 個媒材標籤'),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTagController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '自訂標籤，例如：光影練習',
                  isDense: true,
                ),
                onSubmitted: (_) => _addCustomTag(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(onPressed: _addCustomTag, child: const Text('新增')),
          ],
        ),
        if (_customTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in _customTags)
                InputChip(
                  label: Text('#$tag'),
                  deleteIcon: const Text('✕', style: TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => _customTags.remove(tag)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _attachments.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _attachments[i].file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatFileSize(_attachments[i].size),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _attachments.removeAt(i)),
                  child: const Text('移除'),
                ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: _attachments.length >= _maxAttachments ? null : _pickAttachments,
          child: Text('新增檔案（${_attachments.length}/$_maxAttachments）'),
        ),
      ],
    );
  }

  Widget _buildSafetyLabels() {
    final missing = _isNsfw == null || _isAiGenerated == null;
    final showError = _labelError && missing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showError ? Colors.red.shade400 : Colors.grey.shade300,
          width: showError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('安全標籤（必填）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            showError ? '兩項都需要回答才能發布' : '兩項都需要回答，讓大家自行選擇是否要看到',
            style: TextStyle(
              fontSize: 12,
              color: showError ? Colors.red.shade600 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _labelQuestion(
            title: '成人內容（NSFW）',
            hint: '含裸露、性暗示、血腥等請選「是」',
            value: _isNsfw,
            onChanged: (v) => setState(() => _isNsfw = v),
          ),
          const SizedBox(height: 16),
          _labelQuestion(
            title: 'AI 生成內容',
            hint: '以 AI 產生或主要由 AI 生成的圖像請選「是」',
            value: _isAiGenerated,
            onChanged: (v) => setState(() => _isAiGenerated = v),
          ),
        ],
      ),
    );
  }

  Widget _labelQuestion({
    required String title,
    required String hint,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('是')),
              ButtonSegment(value: false, label: Text('否')),
            ],
            selected: value == null ? <bool>{} : {value},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onChanged(selection.first);
            },
          ),
        ),
      ],
    );
  }
}
