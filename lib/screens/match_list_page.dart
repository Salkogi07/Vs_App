import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/supabase_service.dart';
import 'create_match_page.dart';

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
    _future = _srv.getMatches();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('매치 목록')),
    body: FutureBuilder<List<MatchModel>>(
      future: _future,
      builder: (c, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final m = list[i];
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(m.a.avatarUrl)),
              title: Text('${m.a.name} vs ${m.b.name}'),
              subtitle: Text(
                  '${m.startAt} ~ ${m.endAt}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => CreateMatchPage(existing: m),
                    ));
                    setState(_load);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _srv.deleteMatch(m.id);
                    setState(_load);
                  },
                ),
              ]),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const CreateMatchPage()));
        setState(_load);
      },
      child: const Icon(Icons.add),
    ),
  );
}
