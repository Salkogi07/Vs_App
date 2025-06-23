// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  // ← 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vs_app/screens/character_registration_page.dart';
import 'package:vs_app/screens/create_match_page.dart';
import 'package:vs_app/screens/home_page.dart';
import 'package:vs_app/screens/match_list_page.dart';
import 'package:vs_app/screens/vote_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) .env 파일 로드
  await dotenv.load(fileName: ".env");

  // 2) Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,         // ex) https://xyzabc123.supabase.co
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,// 실제 anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '토너먼트 앱',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,

      // ─── 로케일 지원 설정 ─────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,   // Material 위젯 로컬라이징
        GlobalWidgetsLocalizations.delegate,    // 기본 위젯 로컬라이징
        GlobalCupertinoLocalizations.delegate,  // Cupertino 위젯 로컬라이징
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],

      routes: {
        '/': (context) => const HomePage(),
        '/character-register': (context) => const CharacterRegistrationPage(),
        '/create-match': (context) => const CreateMatchPage(),
        '/match-list': (context) => const MatchListPage(),
        '/vote': (context) => const VotePage(),
      },
    );
  }
}
