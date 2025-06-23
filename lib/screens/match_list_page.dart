// lib/pages/match_list_page.dart

import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/supabase_service.dart';
import 'create_match_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인하고 접속해 주세요."),)
      );
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
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(m.a.avatarUrl),
                  ),
                  title: Text('${m.a.name}  vs  ${m.b.name}'),
                  subtitle: Text(
                    '${_fmt(m.startAt)} - ${_fmt(m.endAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // 수정 모드로 이동(추후 구현)
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateMatchPage(existing: m),
                      ),
                    );
                    _load();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CreateMatchPage()));
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
