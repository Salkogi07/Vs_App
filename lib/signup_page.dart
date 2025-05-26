import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _signup() async{
    final email = emailController.text.trim();
    final pw = pwController.text.trim();

    try {
      await supabase.auth.signUp(
          email: email,
          password: pw
      );

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 성공! \n 이메일을 인증을 진행한 뒤에 다시 로그인 해보세요."))
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원가입 실패: ${e}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              controller: pwController,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _signup,
              child: const Text("회원가입"),
            )
          ],
        ),
      ),
    );
  }
}
