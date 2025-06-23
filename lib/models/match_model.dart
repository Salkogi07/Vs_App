// lib/models/match_model.dart

import 'character.dart';

class MatchModel {
  final String id;
  final Character a;
  final Character b;
  final DateTime endAt;
  final String? winnerId; // 승자의 캐릭터 ID, null일 수 있음 (무승부 또는 미정)

  MatchModel({
    required this.id,
    required this.a,
    required this.b,
    required this.endAt,
    this.winnerId,
  });

  /// Supabase에서 받아온 Map과 두 캐릭터 객체를 전달받아 MatchModel 생성
  factory MatchModel.fromMap(
      Map<String, dynamic> m, Character ca, Character cb) {
    return MatchModel(
      id: m['id'] as String,
      a: ca,
      b: cb,
      endAt: DateTime.parse(m['end_at'] as String).toLocal(),
      winnerId: m['winner_id'] as String?, // 'winner_id'는 null일 수 있습니다.
    );
  }
}