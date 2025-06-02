// lib/pages/character_registration_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class CharacterRegistrationPage extends StatefulWidget {
  const CharacterRegistrationPage({super.key});
  @override
  State<CharacterRegistrationPage> createState() =>
      _CharacterRegistrationPageState();
}

class _CharacterRegistrationPageState
    extends State<CharacterRegistrationPage> {
  final _srv = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  File? _pickedImage; // 모바일용
  Uint8List? _pickedBytes; // 웹용
  String? _avatarUrl;
  bool _isUploading = false;

  final _nameCtrl = TextEditingController();
  final _attrCtrl = TextEditingController(); // 속성/소개 입력

  /// 1) 이미지 선택
  Future<void> _selectImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          _pickedImage = null;
          _avatarUrl = null;
        });
      } else {
        setState(() {
          _pickedImage = File(picked.path);
          _pickedBytes = null;
          _avatarUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류 발생: $e')),
        );
      }
    }
  }

  /// 2) 이미지 업로드 + 캐릭터 생성
  Future<void> _uploadAndCreate() async {
    final name = _nameCtrl.text.trim();
    final attributes = _attrCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('먼저 이름을 입력해주세요.')));
      return;
    }
    if (_pickedImage == null && _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('먼저 이미지를 선택해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // (1) Supabase Storage에 이미지 업로드 → URL 반환
      String avatarUrl;
      if (kIsWeb) {
        // 웹에서는 File이 아닌 Uint8List를 File처럼 래핑해서 넘긴다.
        final tmpFile = File.fromRawPath(_pickedBytes!);
        avatarUrl = await _srv.uploadAvatar(tmpFile);
      } else {
        avatarUrl = await _srv.uploadAvatar(_pickedImage!);
      }

      // (2) 캐릭터 생성 (DB에 삽입)
      await _srv.createCharacter(
        name: name,
        avatarUrl: avatarUrl,
        attributes: attributes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('캐릭터 등록 완료')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _attrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캐릭터 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ─── 이미지 미리보기 ────────────────────────
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: () {
                    if (_pickedBytes != null) {
                      return Image.memory(_pickedBytes!);
                    } else if (_pickedImage != null) {
                      return Image.file(_pickedImage!);
                    } else {
                      return const Text('이미지 선택 필요');
                    }
                  }(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 이미지 선택 버튼 ───────────────────────
            ElevatedButton.icon(
              onPressed: _selectImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('이미지 선택'),
            ),
            const SizedBox(height: 24),

            // ─── 이름 입력 필드 ─────────────────────────
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '캐릭터 이름',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 속성(소개) 입력 필드 ────────────────────
            TextField(
              controller: _attrCtrl,
              decoration: InputDecoration(
                labelText: '캐릭터 속성/소개',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ─── 등록 버튼 ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndCreate,
                child: _isUploading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
