import 'package:flutter/material.dart';
import 'dart:ui'; // Shadow를 사용하기 위해 import

import '../models/match_model.dart';
import '../services/supabase_service.dart';

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
  }

  void _load() {
    setState(() {
      _future = _srv.fetchMatches();
    });
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
                          Expanded(child: _CharacterItemView(avatarUrl: m.a.avatarUrl)),

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
                          Expanded(child: _CharacterItemView(avatarUrl: m.b.avatarUrl)),
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

/// 캐릭터 이미지와 프레임을 표시하는 재사용 가능한 위젯
class _CharacterItemView extends StatelessWidget {
  final String avatarUrl;

  const _CharacterItemView({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    // AspectRatio를 통해 위젯의 비율을 고정
    return AspectRatio(
      aspectRatio: 45 / 68,
      // LayoutBuilder를 사용하여 부모 위젯의 크기를 얻음
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 부모 위젯 너비의 20%를 패딩으로 사용 (이 값을 조절하여 여백 크기 변경)
          final double dynamicPadding = constraints.maxWidth * 0.25;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 캐릭터 이미지 (배경)
              Padding(
                // 계산된 동적 패딩 적용
                padding: EdgeInsets.all(dynamicPadding),
                child: ClipRRect(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
            ],
          );
        },
      ),
    );
  }
}