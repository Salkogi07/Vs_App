import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vs_app/signin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;


  Future<void> _login() async{
    final email = emailController.text.trim();
    final pw = pwController.text.trim();


    try {
      final response = await supabase.auth.signInWithPassword(
          email: email,
          password: pw
      );

      if (response.user != null) {
        Navigator.pushReplacementNamed(context, '/');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("로그인 성공"),)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $e"),)
      );
    }

  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 12,),
            TextField(
              controller: pwController,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 12,),
            ElevatedButton(
                onPressed: _login,
                child: const Text('로그인')
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/signin"),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),

    );
  }
}
