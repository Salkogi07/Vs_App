// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  // ← 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vs_app/login_page.dart';

import 'package:vs_app/models/match_model.dart';

import 'package:vs_app/screens/character_registration_page.dart';
import 'package:vs_app/screens/create_match_page.dart';
import 'package:vs_app/screens/home_page.dart';
import 'package:vs_app/screens/match_list_page.dart';
import 'package:vs_app/screens/vote_page.dart';
import 'package:vs_app/signin_page.dart';

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
        '/vote': (context) {
          // 1. ModalRoute를 통해 arguments를 가져옵니다.
          final arguments = ModalRoute.of(context)?.settings.arguments;

          // 2. arguments가 MatchModel 타입인지 확인하고, 아니면 에러를 발생시킵니다.
          if (arguments is MatchModel) {
            // 3. 올바른 타입이라면 VotePage를 생성하여 반환합니다.
            return VotePage(match: arguments);
          } else {
            // 4. (방어 코드) arguments가 없거나 타입이 다를 경우, 에러 페이지나 이전 페이지로 돌아가는 로직을 추가할 수 있습니다.
            // 여기서는 간단하게 에러를 표시하는 Scaffold를 반환합니다.
            return Scaffold(
              appBar: AppBar(title: const Text('오류')),
              body: const Center(
                child: Text('잘못된 접근입니다. 매치 정보가 없습니다.'),
              ),
            );
          }
        },
        '/login': (context) => const LoginPage(),
        '/signin': (context) => const SignUpPage(),
      },
    );
  }
}
