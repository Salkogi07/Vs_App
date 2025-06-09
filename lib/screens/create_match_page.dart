// lib/pages/create_match_page.dart

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

  List<Character> _searchResults = [];
  final _searchCtrl = TextEditingController();

  Character? _selectedA;
  Character? _selectedB;

  DateTime? _startAt;
  DateTime? _endAt;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedA = widget.existing!.a;
      _selectedB = widget.existing!.b;
      _startAt = widget.existing!.startAt;
      _endAt = widget.existing!.endAt;
    }
    _loadAllCharacters();
  }

  Future<void> _loadAllCharacters() async {
    try {
      final list = await _srv.fetchCharacters(keyword: '');
      setState(() {
        _searchResults = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('캐릭터 목록 조회 오류: $e')),
        );
      }
    }
  }

  Future<void> _searchCharacters(String keyword) async {
    try {
      final list = await _srv.fetchCharacters(keyword: keyword);
      setState(() {
        _searchResults = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류 발생: $e')),
        );
      }
    }
  }

  Future<void> _saveMatch() async {
    if (_selectedA == null || _selectedB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('두 캐릭터를 모두 선택해주세요.')),
      );
      return;
    }
    if (_selectedA!.id == _selectedB!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('같은 캐릭터로 매치를 생성할 수 없습니다.')),
      );
      return;
    }
    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매치 시작/종료 시간을 선택해주세요.')),
      );
      return;
    }
    if (_endAt!.isBefore(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _srv.createMatch(
        charAId: _selectedA!.id,
        charBId: _selectedB!.id,
        startAt: _startAt!,
        endAt: _endAt!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매치가 생성되었습니다.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매치 생성 중 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 날짜/시간 선택 헬퍼
  Future<DateTime?> _pickDateTime({required DateTime? initial}) async {
    // 1) 날짜 선택
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );
    if (date == null) return null;

    // 2) 시간 선택 (24시간 포맷)
    final time = await showTimePicker(
      context: context,
      initialTime:
      initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return null;

    // 3) 합쳐서 반환
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _format({required DateTime dt}) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '매치 생성' : '매치 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 캐릭터 검색
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: '캐릭터 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchCharacters,
            ),
            const SizedBox(height: 12),
            // 캐릭터 그리드
            Expanded(
              child: GridView.builder(
                itemCount: _searchResults.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (ctx, idx) {
                  final c = _searchResults[idx];
                  final isA = _selectedA?.id == c.id;
                  final isB = _selectedB?.id == c.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isA) {
                          _selectedA = null;
                        } else if (isB) {
                          _selectedB = null;
                        } else if (_selectedA == null) {
                          _selectedA = c;
                        } else if (_selectedB == null) {
                          _selectedB = c;
                        } else {
                          _selectedA = c;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        (isA || isB) ? Colors.blue[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                          (isA || isB) ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(c.avatarUrl),
                            radius: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.name,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.attributes,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            // 선택된 슬롯 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SlotDisplay(label: 'A 슬롯', character: _selectedA),
                _SlotDisplay(label: 'B 슬롯', character: _selectedB),
              ],
            ),
            const SizedBox(height: 24),
            // 시작 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('시작 시간'),
                TextButton(
                  onPressed: () async {
                    final dt = await _pickDateTime(initial: _startAt);
                    if (dt != null) setState(() => _startAt = dt);
                  },
                  child: Text(
                    _startAt != null ? _format(dt: _startAt!) : '선택',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 종료 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('종료 시간'),
                TextButton(
                  onPressed: () async {
                    final dt = await _pickDateTime(initial: _endAt);
                    if (dt != null) setState(() => _endAt = dt);
                  },
                  child: Text(
                    _endAt != null ? _format(dt: _endAt!) : '선택',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMatch,
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotDisplay extends StatelessWidget {
  final String label;
  final Character? character;

  const _SlotDisplay({
    required this.label,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: character == null ? Colors.grey[200] : Colors.green[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: character == null ? Colors.grey[400]! : Colors.green,
          width: 2,
        ),
      ),
      child: character == null
          ? Center(child: Text(label))
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(character!.avatarUrl),
            radius: 24,
          ),
          const SizedBox(height: 4),
          Text(character!.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
