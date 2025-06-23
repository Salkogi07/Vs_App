// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:vs_app/login_page.dart';
import 'character_registration_page.dart';
import 'match_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;




  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('토너먼트 앱'),

      actions: [
        IconButton(
            onPressed: () async{
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, "/main");
            },
            icon: const Icon(Icons.logout))
      ],
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CharacterRegistrationPage()),
            ),
            child: const Text('캐릭터 등록'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MatchListPage()),
            ),
            child: const Text('매치 관리'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('로그인'),
          ),
        ],
      ),
    ),
  );
}
