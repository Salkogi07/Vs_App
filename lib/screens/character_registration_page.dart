import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterRegistrationPage extends StatefulWidget {
  const CharacterRegistrationPage({super.key});
  @override
  State<CharacterRegistrationPage> createState() =>
      _CharacterRegistrationPageState();
}

class _CharacterRegistrationPageState
    extends State<CharacterRegistrationPage> {

  final _srv    = SupabaseService();
  final _picker = ImagePicker();

  File? _pickedImage;
  Uint8List? _pickedBytes;
  bool _isUploading = false;

  final _nameCtrl = TextEditingController();
  final _attrCtrl = TextEditingController();

  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async{
    final user = Supabase.instance.client.auth.currentUser;

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (user != null){
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인하고 접속해 주세요."),)
      );
    }
  }

  Future<void> _selectImage() async {
    try {
      final picked = await _picker.pickImage(
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
        });
      } else {
        setState(() {
          _pickedImage = File(picked.path);
          _pickedBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('이미지 선택 중 오류: $e')));
      }
    }
  }

  Future<void> _uploadAndCreate() async {
    final name       = _nameCtrl.text.trim();
    final attributes = _attrCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }
    if (_pickedImage == null && _pickedBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미지를 선택해주세요')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // ① Storage에 업로드 → path 반환
      late final String avatarPath;
      if (kIsWeb) {
        avatarPath = await _srv.uploadAvatarWeb(_pickedBytes!);
      } else {
        avatarPath = await _srv.uploadAvatarMobile(_pickedImage!);
      }

      // ② path + name, attributes → DB에 저장 (public URL은 서비스 내부에서 생성)
      await _srv.createCharacter(
        name: name,
        avatarPath: avatarPath,
        attributes: attributes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('등록 완료')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('등록 중 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 이미지 미리보기
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: () {
                    if (_pickedBytes != null) return Image.memory(_pickedBytes!);
                    if (_pickedImage != null) return Image.file(_pickedImage!);
                    return const Text('이미지 선택 필요');
                  }(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 선택 버튼
            ElevatedButton.icon(
              onPressed: _selectImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('이미지 선택'),
            ),
            const SizedBox(height: 24),

            // 이름 입력
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

            // 속성/소개 입력
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

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndCreate,
                child: _isUploading
                    ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
