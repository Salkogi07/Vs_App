import 'package:flutter/material.dart';
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
                // --- 여기서부터 수정 ---
                child: Card(
                  elevation: 2,
                  child: AspectRatio(
                    // 이미지의 가로/세로 비율을 지정합니다. (예: 16:9)
                    aspectRatio: 2720 / 960,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/match-background_image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // A 아이템 섹션
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FractionallySizedBox(
                                heightFactor: 1,
                                child: AspectRatio(
                                  aspectRatio: 45 / 68,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage('assets/character-item-layer.png'),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          // B 아이템 섹션
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    m.b.avatarUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                color: Colors.blue,
                                child: Text(
                                  m.b.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- 여기까지 수정 ---
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

  String _fmt(DateTime dt) {
    final yy = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final da = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$yy-$mo-$da $hh:$mi';
  }
}