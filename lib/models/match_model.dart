// lib/models/match_model.dart

import 'character.dart';

class MatchModel {
  final String id;
  final Character a;
  final Character b;
  final DateTime startAt;
  final DateTime endAt;

  MatchModel({
    required this.id,
    required this.a,
    required this.b,
    required this.startAt,
    required this.endAt,
  });

  /// Supabase에서 받아온 Map과 두 캐릭터 객체를 전달받아 MatchModel 생성
  factory MatchModel.fromMap(
      Map<String, dynamic> m, Character ca, Character cb) {
    return MatchModel(
      id: m['id'] as String,
      a: ca,
      b: cb,
      startAt: DateTime.parse(m['start_at'] as String).toLocal(),
      endAt: DateTime.parse(m['end_at'] as String).toLocal(),
    );
  }
}
