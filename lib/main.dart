// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vs_app/screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) .env 파일 로드
  await dotenv.load(fileName: ".env");

  // 2) Supabase 초기화 (URL과 anon key를 실제 값으로 대체)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,        // ← https://xyzabc123.supabase.co
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,// ← 실제 anon key
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
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
