import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/commission.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/commission_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/disclaimer.dart';
import '../utils/time_utils.dart';
import '../widgets/segment_tabs.dart';
import '../widgets/tag_editor.dart';

class _Picked {
  final String name;
  final Uint8List bytes;

  const _Picked(this.name, this.bytes);

  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
}

/// Create a commission request or an offer. Pops with `true` when published.
class CommissionEditScreen extends StatefulWidget {
  const CommissionEditScreen({super.key});

  @override
  State<CommissionEditScreen> createState() => _CommissionEditScreenState();
}

class _CommissionEditScreenState extends State<CommissionEditScreen> {
  static const _maxImages = 4;
  static const _maxImageBytes = 20 * 1024 * 1024;
  static const _tagSuggestions = ['原創角色', '頭像', '立繪', 'Q版', 'Live2D', 'Logo', '插畫'];

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  final _contact = TextEditingController();
  final _images = <_Picked>[];

  late final Future<List<String>> _categories = CategoryService().names();

  int _typeIndex = 0;
  String? _category;
  DateTime? _deadline;
  List<String> _tags = [];
  bool? _isNsfw;
  bool _agreed = false;
  bool _labelError = false;
  bool _submitting = false;
  double _progress = 0;

  CommissionType get _type =>
      _typeIndex == 0 ? CommissionType.request : CommissionType.offer;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budget.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return _message('最多只能附 $_maxImages 張圖片');
    try {
      final picker = ImagePicker();
      final List<XFile> files;
      if (remaining == 1) {
        final one = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
        files = one == null ? [] : [one];
      } else {
        files = await picker.pickMultiImage(imageQuality: 90, limit: remaining);
      }
      for (final file in files.take(remaining)) {
        final bytes = await file.readAsBytes();
        if (bytes.length > _maxImageBytes) {
          _message('${file.name} 超過 20MB，已略過');
          continue;
        }
        _images.add(_Picked(file.name, bytes));
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _message('無法取得圖片，請確認已允許存取相簿');
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    final contact = _contact.text.trim();
    if (title.isEmpty) return _message('請輸入標題');
    if (contact.isEmpty) return _message('請填寫站外聯絡方式');
    if (_isNsfw == null) {
      setState(() => _labelError = true);
      return _message('請回答是否為成人內容');
    }
    if (!_agreed) return _message('請先閱讀並同意免責聲明');

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() {
      _submitting = true;
      _progress = 0;
    });

    final service = CommissionService();
    final storage = StorageService();
    final ref = service.newRef();
    final uploaded = <String>[];

    try {
      final total = _images.fold<int>(0, (acc, i) => acc + i.bytes.length);
      final done = List<int>.filled(_images.length, 0);
      final urls = await Future.wait([
        for (var i = 0; i < _images.length; i++)
          storage
              .uploadBytes(
                path: 'commissions/${user.uid}/${ref.id}/$i.${_images[i].extension}',
                bytes: _images[i].bytes,
                contentType: StorageService.imageMimeType(_images[i].extension),
                onProgress: (bytes, _) {
                  done[i] = bytes;
                  if (mounted && total > 0) {
                    setState(() =>
                        _progress = (done.fold<int>(0, (a, b) => a + b) / total).clamp(0.0, 0.98));
                  }
                },
              )
              .then((file) {
            uploaded.add(file.path);
            return file.url;
          }),
      ]);

      await service.create(
        ref,
        Commission(
          id: ref.id,
          userId: user.uid,
          userName: user.displayName ?? '',
          userPhotoUrl: user.photoURL ?? '',
          type: _type,
          title: title,
          description: _description.text.trim(),
          category: _category ?? '',
          tags: _tags,
          budgetText: _budget.text.trim(),
          deadline: _deadline == null ? null : Timestamp.fromDate(_deadline!),
          contact: contact,
          imageUrls: urls,
          isNsfw: _isNsfw!,
          isOpen: true,
          reportCount: 0,
          createdAt: null,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      await Future.wait(uploaded.map(storage.deleteQuietly));
      if (mounted) _message('發布失敗，請確認網路後再試一次');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequest = _type == CommissionType.request;

    return Scaffold(
      appBar: AppBar(
        title: const Text('發布委託'),
        actions: [
          TextButton(onPressed: _submitting ? null : _submit, child: const Text('發布')),
        ],
        bottom: _submitting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            SegmentTabs(
              labels: const ['我要委託（徵稿）', '我要接單（展示）'],
              selected: _typeIndex,
              onChanged: (i) => setState(() => _typeIndex = i),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: '標題',
                hintText: isRequest ? '例如：徵 VTuber 立繪' : '例如：頭像／半身像接單中',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: isRequest ? '需求內容' : '服務內容與流程',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budget,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: isRequest ? '預算' : '價格',
                hintText: '例如：NT\$1,500 起，可議',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null
                        ? (isRequest ? '期限（選填）' : '可接單至（選填）')
                        : '${isRequest ? '期限' : '可接單至'}：${formatDate(Timestamp.fromDate(_deadline!))}',
                    style: TextStyle(
                      color: _deadline == null ? AppColors.muted : AppColors.ink,
                      fontWeight: _deadline == null ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ),
                if (_deadline != null)
                  TextButton(onPressed: () => setState(() => _deadline = null), child: const Text('清除')),
                OutlinedButton(onPressed: _pickDeadline, child: const Text('選擇日期')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('分類（選填）', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _categories,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return snapshot.hasError ? const Text('分類載入失敗') : const LinearProgressIndicator();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in snapshot.data!)
                      ChoiceChip(
                        label: Text(name),
                        showCheckmark: false,
                        selected: _category == name,
                        onSelected: (selected) => setState(() => _category = selected ? name : null),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('標籤', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TagEditor(
              tags: _tags,
              suggestions: _tagSuggestions,
              onChanged: (tags) => setState(() => _tags = tags),
            ),
            const SizedBox(height: 20),
            Text(
              '${isRequest ? '參考圖' : '作品範例'}（${_images.length}/$_maxImages，選填）',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _images.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_images[i].bytes, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('移除',
                                  style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_images.length < _maxImages)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('新增圖片'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contact,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: '站外聯絡方式（必填）',
                hintText: 'LINE ID／IG／Email 等',
              ),
            ),
            const SizedBox(height: 12),
            _nsfwQuestion(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('免責聲明', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(commissionDisclaimer,
                      style: const TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xFF5C544C))),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      title: const Text('我已閱讀並同意', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _nsfwQuestion() {
    final showError = _labelError && _isNsfw == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showError ? Colors.red.shade400 : AppColors.line,
          width: showError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('成人內容（必填）', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            showError ? '請回答這題才能發布' : '涉及裸露、性暗示或血腥的委託請選「是」',
            style: TextStyle(
              fontSize: 12,
              color: showError ? Colors.red.shade600 : AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('是')),
                ButtonSegment(value: false, label: Text('否')),
              ],
              selected: _isNsfw == null ? <bool>{} : {_isNsfw!},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) setState(() => _isNsfw = s.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
