// lib/upload_page.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // 모바일(iOS/Android)일 때는 File을, Web일 때는 Uint8List(바이트)로 이미지를 저장
  File? _pickedFileMobile;
  Uint8List? _pickedFileWebBytes;

  String? _uploadedImageUrl;
  bool _isUploading = false;

  /// 1) 이미지 선택 (모바일: File, 웹: Uint8List)
  Future<void> _selectImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) {
        return; // 사용자가 선택 취소
      }

      if (kIsWeb) {
        // Web 환경: XFile에서 바이트 읽기
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFileWebBytes = bytes;
          _pickedFileMobile = null;   // 모바일 타입 초기화
          _uploadedImageUrl = null;
        });
      } else {
        // 모바일 환경: File 객체 생성
        final file = File(picked.path);
        setState(() {
          _pickedFileMobile = file;
          _pickedFileWebBytes = null; // 웹 타입 초기화
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류 발생: $e')),
      );
    }
  }

  /// 2) Supabase Storage에 업로드 (Web ↔ Mobile 분기)
  Future<void> _uploadImage() async {
    // 1) 파일이 선택되지 않았을 때 처리
    if (!kIsWeb && _pickedFileMobile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 이미지를 선택해주세요.')),
      );
      return;
    }
    if (kIsWeb && _pickedFileWebBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 이미지를 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 2) 파일명을 타임스탬프 기반으로 고유 생성
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'avatars/$fileName';

      String fullPath;

      if (kIsWeb) {
        // ===== Web에서 uploadBinary 사용 =====
        final bytes = _pickedFileWebBytes!;
        fullPath = await supabase.storage
            .from('avatars')
            .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      } else {
        // ===== Mobile(iOS/Android)에서 upload 사용 =====
        final file = _pickedFileMobile!;
        fullPath = await supabase.storage
            .from('avatars')
            .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      }

      // 3) Public 버킷인 경우 getPublicUrl 호출 (반환 타입: String)
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fullPath);

      setState(() {
        _uploadedImageUrl = publicUrl;
      });
    } catch (error) {
      // Supabase SDK가 실패 시 PostgrestException 등을 throw
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 오류: $error')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase 이미지 업로드'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ─── 이미지 미리보기 영역 ───────────────────────────────
            Expanded(
              child: Center(
                child: () {
                  if (kIsWeb) {
                    // 웹: Uint8List -> Image.memory
                    if (_pickedFileWebBytes != null) {
                      return Image.memory(_pickedFileWebBytes!);
                    } else {
                      return const Text('웹 환경: 이미지를 선택해주세요.');
                    }
                  } else {
                    // 모바일: File -> Image.file
                    if (_pickedFileMobile != null) {
                      return Image.file(_pickedFileMobile!);
                    } else {
                      return const Text('모바일 환경: 이미지를 선택해주세요.');
                    }
                  }
                }(),
              ),
            ),

            const SizedBox(height: 16),

            // ─── 이미지 선택 버튼 ─────────────────────────────────
            ElevatedButton.icon(
              onPressed: _selectImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 이미지 선택'),
            ),

            const SizedBox(height: 16),

            // ─── 업로드 버튼 ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                child: _isUploading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('업로드'),
              ),
            ),

            const SizedBox(height: 16),

            // ─── 업로드 완료 URL 표시 ─────────────────────────────
            if (_uploadedImageUrl != null) ...[
              const Text('업로드 완료! 공개 URL:'),
              const SizedBox(height: 8),
              SelectableText(
                _uploadedImageUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 16),
              // ─── 선택 사항: 네트워크 이미지 미리보기 ─────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _uploadedImageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
