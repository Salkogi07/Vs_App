import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/match_model.dart';
import '../services/supabase_service.dart';

class CreateMatchPage extends StatefulWidget {
  final MatchModel? existing;
  const CreateMatchPage({super.key, this.existing});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final _srv = SupabaseService();
  final _searchCtrl = TextEditingController();

  List<Character> _results = [];
  Character? _a, _b;
  DateTime? _startAt, _endAt;
  bool _loading = false;

  Future<void> _search() async {
    if (_searchCtrl.text.isEmpty) return;
    final res = await _srv.searchCharacters(_searchCtrl.text.trim());
    setState(() => _results = res);
  }

  Future<DateTime?> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _a = widget.existing!.a;
      _b = widget.existing!.b;
      _startAt = widget.existing!.startAt;
      _endAt = widget.existing!.endAt;
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
        title: Text(widget.existing != null ? '매치 수정' : '매치 생성')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: '캐릭터 검색',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ]),
        if (_results.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: _results.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final c = _results[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_a == null) {
                        _a = c;
                      } else if (_b == null) {
                        _b = c;
                      }
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        CircleAvatar(
                            backgroundImage: NetworkImage(c.avatarUrl)),
                        Text(c.name, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(children: [
          _buildSlot('A', _a),
          const SizedBox(width: 16),
          _buildSlot('B', _b),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final dt = await _pickDateTime();
                if (dt != null) setState(() => _startAt = dt);
              },
              child: Text(_startAt == null
                  ? '시작 시간 선택'
                  : _startAt!.toString()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final dt = await _pickDateTime();
                if (dt != null) setState(() => _endAt = dt);
              },
              child: Text(_endAt == null
                  ? '종료 시간 선택'
                  : _endAt!.toString()),
            ),
          ),
        ]),
        const Spacer(),
        ElevatedButton(
          onPressed: _loading ||
              _a == null ||
              _b == null ||
              _startAt == null ||
              _endAt == null
              ? null
              : () async {
            setState(() => _loading = true);
            if (widget.existing != null) {
              await _srv.updateMatch(
                  widget.existing!.id, _startAt!, _endAt!);
            } else {
              await _srv.createMatch(
                  _a!.id, _b!.id, _startAt!, _endAt!);
            }
            if (mounted) Navigator.pop(ctx);
          },
          child: _loading
              ? const CircularProgressIndicator()
              : Text(widget.existing != null ? '수정 저장' : '생성하기'),
        ),
      ]),
    ),
  );

  Widget _buildSlot(String label, Character? c) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigo),
          borderRadius: BorderRadius.circular(8),
        ),
        child: c == null
            ? Center(child: Text('$label 비어있음'))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundImage: NetworkImage(c.avatarUrl)),
            Text(c.name),
          ],
        ),
      ),
    );
  }
}
