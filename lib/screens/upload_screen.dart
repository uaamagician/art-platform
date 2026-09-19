import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/post.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = StorageService();

  XFile? _pickedImage;
  Uint8List? _previewBytes;
  String? _selectedCategory;
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImage = image;
      _previewBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    if (_pickedImage == null) {
      _showMessage('請先選擇一張圖片');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showMessage('請輸入標題');
      return;
    }
    if (_selectedCategory == null) {
      _showMessage('請選擇分類');
      return;
    }

    setState(() => _submitting = true);
    try {
      final imageUrl = await _storageService.uploadPostImage(
        file: _pickedImage!,
        userId: user.uid,
      );

      final post = Post(
        id: '',
        userId: user.uid,
        imageUrl: imageUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        tags: _selectedTags.toList(),
        createdAt: null,
      );

      await appFirestore.collection('posts').add(post.toFirestore());

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('上傳失敗：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增投稿'),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('送出'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImagePicker(),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '標題',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '描述',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('分類', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCategoryPicker(),
          const SizedBox(height: 24),
          const Text('媒材標籤', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTagPicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _previewBytes == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 40),
                    SizedBox(height: 8),
                    Text('點擊選擇圖片'),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_previewBytes!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('從相簿選擇'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return FutureBuilder<QuerySnapshot>(
      future: appFirestore.collection('categories').orderBy('order').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docs.map((doc) {
            final name = (doc.data() as Map<String, dynamic>)['name'] as String;
            final selected = _selectedCategory == name;
            return ChoiceChip(
              label: Text(name),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTagPicker() {
    return FutureBuilder<QuerySnapshot>(
      future: appFirestore.collection('tags').orderBy('name').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docs.map((doc) {
            final name = (doc.data() as Map<String, dynamic>)['name'] as String;
            final selected = _selectedTags.contains(name);
            return FilterChip(
              label: Text(name),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedTags.add(name);
                  } else {
                    _selectedTags.remove(name);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }
}
