// lib/services/supabase_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/match_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  /// 1) Mobile: File → 상대경로(path)만 반환
  Future<String> uploadAvatarMobile(File file) async {
    final ext      = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final String path = 'characters/$fileName';

    // ← upload는 오직 path("characters/xxx.png")만 반환 :contentReference[oaicite:0]{index=0}
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

  /// 2) Web: Uint8List → 상대경로(path)만 반환
  Future<String> uploadAvatarWeb(Uint8List bytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final String path = 'characters/$fileName';

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
        .getPublicUrl(path);  // getPublicUrl은 bucket 기준 path만 받습니다 :contentReference[oaicite:1]{index=1}
  }

  /// 4) 캐릭터 생성: 실제 DB에는 public URL을 저장
  Future<void> createCharacter({
    required String name,
    required String avatarPath,   // path만 받음
    required String attributes,
  }) async {
    final publicUrl = _makePublicUrl(avatarPath);
    await _db.from('characters').insert({
      'name'       : name,
      'avatar_url' : publicUrl,   // → 여기엔 "…/avatars/characters/xxx.png" 한 번만 들어갑니다
      'attributes' : attributes,
    });
  }

  /// ──────────────────────────────────────────────────────────────────────
  /// 3) 캐릭터 리스트 조회: name ILIKE '%keyword%' 속성 검색
  /// ──────────────────────────────────────────────────────────────────────
  Future<List<Character>> fetchCharacters({String keyword = ''}) async {
    try {
      PostgrestFilterBuilder query = _db.from('characters').select();

      if (keyword.isNotEmpty) {
        query = query.filter('name', 'ilike', '%$keyword%');
      }

      final List<dynamic> raw = await query;
      return raw
          .map((e) => Character.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// ──────────────────────────────────────────────────────────────────────
  /// 4) 단일 캐릭터 조회 (ID로)
  /// ──────────────────────────────────────────────────────────────────────
  Future<Character?> getCharacterById(String id) async {
    try {
      final Map<String, dynamic>? raw = await _db
          .from('characters')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (raw == null) return null;
      return Character.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  /// ──────────────────────────────────────────────────────────────────────
  /// 5) 매치 생성: charA, charB, startAt, endAt을 DB에 INSERT
  /// ──────────────────────────────────────────────────────────────────────
  Future<void> createMatch({
    required String charAId,
    required String charBId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    try {
      await _db.from('matches').insert({
        'char_a_id': charAId,
        'char_b_id': charBId,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ──────────────────────────────────────────────────────────────────────
  /// 6) 매치 전체 조회: matches → 필요한 캐릭터 ID 추출 → characters 테이블 조회
  /// ──────────────────────────────────────────────────────────────────────
  Future<List<MatchModel>> fetchMatches() async {
    try {
      // 1) matches 테이블에서 모든 행을 가져옴
      final List<dynamic> rawMatches = await _db.from('matches').select();

      // 2) 필요 캐릭터 ID만 Set에 모음
      final Set<String> charIds = {};
      for (var m in rawMatches) {
        final mm = m as Map<String, dynamic>;
        charIds.add(mm['char_a_id'] as String);
        charIds.add(mm['char_b_id'] as String);
      }
      if (charIds.isEmpty) return [];

      // 3) "('id1','id2',...)" 형태로 문자열 생성
      final String inString = '(${charIds.map((e) => "'$e'").join(",")})';

      // 4) 캐릭터들을 한 번에 조회
      final List<dynamic> rawChars = await _db
          .from('characters')
          .select()
          .filter('id', 'in', inString);

      // 5) Map<id, Character> 형태로 변환
      final Map<String, Character> charMap = {
        for (var c in rawChars)
          (c as Map<String, dynamic>)['id'] as String:
          Character.fromMap(c)
      };

      // 6) MatchModel 리스트로 변환
      return rawMatches.map((m) {
        final Map<String, dynamic> mm = m as Map<String, dynamic>;
        final ca = charMap[mm['char_a_id'] as String]!;
        final cb = charMap[mm['char_b_id'] as String]!;
        return MatchModel.fromMap(mm, ca, cb);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
