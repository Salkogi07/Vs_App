// lib/services/supabase_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/match_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  /// 1) 모바일: File → 상대경로(path)만 반환
  Future<String> uploadAvatarMobile(File file) async {
    final ext      = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path     = 'characters/$fileName';

    await _db
        .storage
        .from('avatars')
        .upload(
      path,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    return path;
  }

  /// 2) 웹: Uint8List → 상대경로(path)만 반환
  Future<String> uploadAvatarWeb(Uint8List bytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final path     = 'characters/$fileName';

    await _db
        .storage
        .from('avatars')
        .uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    return path;
  }

  /// 3) 상대경로(path) → public URL 생성 헬퍼
  String _makePublicUrl(String path) {
    return _db
        .storage
        .from('avatars')
        .getPublicUrl(path);  // 퍼블릭 URL 생성 :contentReference[oaicite:0]{index=0}
  }

  /// 4) 캐릭터 생성: avatarPath(path) → public URL 생성 후 저장
  Future<void> createCharacter({
    required String name,
    required String avatarPath,
    required String attributes,
  }) async {
    final publicUrl = _makePublicUrl(avatarPath);
    await _db.from('characters').insert({
      'name'       : name,
      'avatar_url' : publicUrl,
      'attributes' : attributes,
    });
  }

  /// 5) 캐릭터 리스트 조회
  Future<List<Character>> fetchCharacters({String keyword = ''}) async {
    final query = _db.from('characters').select();
    if (keyword.isNotEmpty) {
      query.filter('name', 'ilike', '%$keyword%');
    }
    final raw = await query;
    return (raw as List)
        .map((e) => Character.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 6) 단일 캐릭터 조회
  Future<Character?> getCharacterById(String id) async {
    final raw = await _db
        .from('characters')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (raw == null) return null;
    return Character.fromMap(raw as Map<String, dynamic>);
  }

  /// 7) 매치 생성: UUID 패턴(RegExp)으로 순수 UUID만 뽑아서 삽입
  Future<void> createMatch({
    required String charAId,
    required String charBId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    // UUID 형식 매칭(RegExp)
    final uuidReg = RegExp(
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{12}'
    );

    // 원본에서 순수 UUID 부분만 추출
    final aMatch = uuidReg.firstMatch(charAId);
    final bMatch = uuidReg.firstMatch(charBId);
    if (aMatch == null || bMatch == null) {
      throw FormatException('잘못된 UUID 형식: $charAId, $charBId');
    }
    final cleanA = aMatch.group(0)!;
    final cleanB = bMatch.group(0)!;

    await _db.from('matches').insert({
      'char_a_id': cleanA,
      'char_b_id': cleanB,
      'start_at' : startAt.toUtc().toIso8601String(),
      'end_at'   : endAt.toUtc().toIso8601String(),
    });
  }

  /// 8) 매치 전체 조회: matches → 필요한 캐릭터 ID만 inFilter 로 조회
  Future<List<MatchModel>> fetchMatches() async {
    // ① matches 모두 가져옴
    final rawMatches = await _db.from('matches').select() as List<dynamic>;

    // ② 필요한 캐릭터 ID 집합
    final charIds = <String>{};
    for (var m in rawMatches) {
      final mm = m as Map<String, dynamic>;
      charIds.add(mm['char_a_id'] as String);
      charIds.add(mm['char_b_id'] as String);
    }
    if (charIds.isEmpty) return [];

    // ③ characters 테이블에서 inFilter 로 한 번에 조회
    final rawChars = await _db
        .from('characters')
        .select()
        .inFilter('id', charIds.toList())  // inFilter 사용 :contentReference[oaicite:1]{index=1}
    as List<dynamic>;

    // ④ Map<id, Character> 로 변환
    final charMap = {
      for (var c in rawChars)
        (c as Map<String, dynamic>)['id'] as String
            : Character.fromMap(c),
    };

    // ⑤ MatchModel 리스트로 조합
    return rawMatches.map((m) {
      final mm = m as Map<String, dynamic>;
      return MatchModel.fromMap(
        mm,
        charMap[mm['char_a_id']]!,
        charMap[mm['char_b_id']]!,
      );
    }).toList();
  }
}
