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

  /// 기본 Flutter 다이얼로그를 사용해 날짜와 시간을 순차적으로 선택
  Future<DateTime?> _pickDateTime({required DateTime? initialDate}) async {
    // 1) 날짜 선택
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko'), // 한국어 로케일
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Material 3 환경에서는 추가 커스터마이징이 필요할 수 있음
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // 헤더 바 색상
              onPrimary: Colors.white, // 헤더 바 글자 색
              onSurface: Colors.black, // 달력 UI 글자 색
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return null;

    // 2) 시간 선택
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return null;

    // 3) 날짜+시간을 합쳐서 반환
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            // ─── 캐릭터 검색 및 선택 영역 ──────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: '캐릭터 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => _searchCharacters(val),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _searchResults.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (ctx, idx) {
                  final c = _searchResults[idx];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedA == null) {
                          _selectedA = c;
                        } else if (_selectedB == null && c.id != _selectedA!.id) {
                          _selectedB = c;
                        } else if (_selectedA?.id == c.id) {
                          _selectedA = null;
                        } else if (_selectedB?.id == c.id) {
                          _selectedB = null;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (_selectedA != null && _selectedA!.id == c.id) ||
                            (_selectedB != null && _selectedB!.id == c.id)
                            ? Colors.blue[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_selectedA != null && _selectedA!.id == c.id) ||
                              (_selectedB != null && _selectedB!.id == c.id)
                              ? Colors.blue
                              : Colors.grey[300]!,
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.attributes,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            // ─── 선택된 A, B 표시 ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SlotDisplay(label: 'A 슬롯', character: _selectedA),
                _SlotDisplay(label: 'B 슬롯', character: _selectedB),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 시작 시간 선택 ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('시작 시간'),
                TextButton(
                  onPressed: () async {
                    final picked = await _pickDateTime(initialDate: _startAt);
                    if (picked != null) {
                      setState(() {
                        _startAt = picked;
                      });
                    }
                  },
                  child: Text(
                    _startAt == null
                        ? '선택'
                        : '${_startAt!.year}-${_startAt!.month.toString().padLeft(2, '0')}-${_startAt!.day.toString().padLeft(2, '0')} '
                        '${_startAt!.hour.toString().padLeft(2, '0')}:${_startAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 종료 시간 선택 ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('종료 시간'),
                TextButton(
                  onPressed: () async {
                    final picked = await _pickDateTime(initialDate: _endAt);
                    if (picked != null) {
                      setState(() {
                        _endAt = picked;
                      });
                    }
                  },
                  child: Text(
                    _endAt == null
                        ? '선택'
                        : '${_endAt!.year}-${_endAt!.month.toString().padLeft(2, '0')}-${_endAt!.day.toString().padLeft(2, '0')} '
                        '${_endAt!.hour.toString().padLeft(2, '0')}:${_endAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 저장 버튼 ─────────────────────────────────
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
