import 'dart:io';
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
  File? _pickedImage;
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('캐릭터 등록')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GestureDetector(
          onTap: () async {
            final img =
            await ImagePicker().pickImage(source: ImageSource.gallery);
            if (img != null) {
              setState(() => _pickedImage = File(img.path));
            }
          },
          child: CircleAvatar(
            radius: 50,
            backgroundImage:
            _pickedImage != null ? FileImage(_pickedImage!) : null,
            child: _pickedImage == null
                ? const Icon(Icons.add_a_photo, size: 32)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: '이름'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
            if (_pickedImage == null ||
                _nameCtrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            final url = await _srv.uploadAvatar(_pickedImage!); // :contentReference[oaicite:3]{index=3}
            await _srv.createCharacter(
                _nameCtrl.text.trim(), url);
            if (mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('등록 완료')));
              Navigator.pop(ctx);
            }
          },
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('등록'),
        ),
      ]),
    ),
  );
}
