import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState(){
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final user = Supabase.instance.client.auth.currentUser;

    await Future.delayed(const Duration(seconds: 1));

    if(!mounted) return;

    if(user != null){
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
            "To DO 앱 시작 중....",
            style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
