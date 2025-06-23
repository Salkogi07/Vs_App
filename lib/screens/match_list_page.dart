import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // Shadow를 사용하기 위해 import

import '../models/match_model.dart';
import '../services/supabase_service.dart';
import 'home_page.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});
  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  final _srv = SupabaseService();
  late Future<List<MatchModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    _checkLogin();
  }

  void _load() {
    setState(() {
      _future = _srv.fetchMatches();
    });
  }

  void _checkLogin() async{
    final user = Supabase.instance.client.auth.currentUser;

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (user != null){

    } else {
      Navigator.pushReplacementNamed(context, '/');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인하고 접속해 주세요."),)
      );
    }
  }

  /// 남은 시간을 "X일 Y시간 남음" 형식의 문자열로 변환합니다.
  String _formatRemainingTime(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now());

    if (difference.isNegative) {
      return '투표 종료';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '$days일 $hours시간 남음';
    } else if (hours > 0) {
      return '$hours시간 남음';
    } else if (minutes > 0) {
      return '$minutes분 남음';
    } else {
      return '곧 종료';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매치 관리'),
      ),
      body: FutureBuilder<List<MatchModel>>(
        future: _future,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return const Center(child: Text('등록된 매치가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final m = matches[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.pushNamed(context, "/vote"),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 2720 / 960,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/match-background_image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // A 아이템 섹션
                          Expanded(child: _CharacterItemView(avatarUrl: m.a.avatarUrl, name: m.a.name)),

                          // 중앙 VS 및 남은 시간 섹션
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    // m.dueDate 대신 m.endAt 사용
                                    _formatRemainingTime(m.endAt),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.black87,
                                            offset: Offset(1.0, 1.0)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // B 아이템 섹션
                          Expanded(child: _CharacterItemView(avatarUrl: m.b.avatarUrl, name: m.b.name)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, "/create-match");
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CharacterItemView extends StatelessWidget {
  final String avatarUrl;
  final String name; // 1. name 파라미터 추가

  // 2. 생성자에 name 추가
  const _CharacterItemView({required this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 45 / 68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double dynamicPadding = constraints.maxWidth * 0.25;
          // 이름 텍스트의 폰트 크기를 동적으로 계산
          final double fontSize = constraints.maxWidth * 0.08;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 캐릭터 이미지 (배경)
              Padding(
                padding: EdgeInsets.all(dynamicPadding),
                child: ClipRRect(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error_outline, color: Colors.white),
                  ),
                ),
              ),
              // 2. 프레임 이미지 (전경)
              Image.asset(
                'assets/character-item-layer.png',
                fit: BoxFit.contain,
              ),

              // 3. 캐릭터 이름 텍스트 (새로 추가)
              Positioned(
                // 부모 높이의 약 10% 위에서부터 텍스트를 배치합니다. (값 조절 가능)
                bottom: constraints.maxHeight * 0.105,
                // 좌우 여백을 주어 텍스트가 프레임 밖으로 나가지 않게 함
                left: constraints.maxWidth * 0.1,
                right: constraints.maxWidth * 0.1,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1, // 이름이 길 경우 한 줄로 제한
                  overflow: TextOverflow.ellipsis, // 넘칠 경우 ...으로 표시
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize, // 동적 폰트 사이즈 적용
                    shadows: const [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black87,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}