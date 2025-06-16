// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:vs_app/login_page.dart';
import 'character_registration_page.dart';
import 'match_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('토너먼트 앱')),
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
