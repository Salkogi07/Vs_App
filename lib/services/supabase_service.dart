// lib/services/supabase_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/match_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  /// ──────────────────────────────────────────────────────────────────────
  /// 1) 이미지 업로드: Mobile(iOS/Android) vs Web 분리 구현
  ///    1-a) 모바일: File 객체를 받아서 upload()
  ///    1-b) 웹: Uint8List(bytes) 배열을 받아서 uploadBinary()
  /// ──────────────────────────────────────────────────────────────────────

  /// 1-a) 모바일 전용: File 객체를 받아 Supabase에 업로드
  Future<String> uploadAvatarMobile(File file) async {
    final String ext = file.path.split('.').last;
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = 'avatars/$fileName.$ext';

    try {
      final String fullPath = await _db.storage
          .from('avatars')
          .upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      // Public URL 생성
      final publicUrl = _db.storage.from('avatars').getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      // 에러 발생 시 그대로 던집니다.
      rethrow;
    }
  }

  /// 1-b) 웹 전용: Uint8List 형태 바이트 배열을 받아 Supabase에 업로드
  Future<String> uploadAvatarWeb(Uint8List bytes) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = 'avatars/$fileName.png';
    // 웹에서는 확장자를 일괄적으로 png로 처리하거나,
    // MIME 타입에 맞추어 직접 지정할 수도 있습니다.

    try {
      final String fullPath = await _db.storage
          .from('avatars')
          .uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      final publicUrl = _db.storage.from('avatars').getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }


  /// ──────────────────────────────────────────────────────────────────────
  /// 2) 캐릭터 생성: Flutter에서 넘겨준 name, avatarUrl, attributes를
  ///    characters 테이블에 INSERT
  /// ──────────────────────────────────────────────────────────────────────
  Future<void> createCharacter({
    required String name,
    required String avatarUrl,
    required String attributes,
  }) async {
    try {
      await _db.from('characters').insert({
        'name': name,
        'avatar_url': avatarUrl,
        'attributes': attributes,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ──────────────────────────────────────────────────────────────────────
  /// 3) 캐릭터 리스트 조회: keyword가 있으면 ILIKE 조건 추가
  /// ──────────────────────────────────────────────────────────────────────
  Future<List<Character>> fetchCharacters({String keyword = ''}) async {
    try {
      PostgrestFilterBuilder query = _db.from('characters').select();

      if (keyword.isNotEmpty) {
        query = query.filter('name', 'ilike', '%$keyword%');
      }
      // 필요한 경우 order()를 호출할 수 있습니다.
      // query = query.order('created_at', ascending: false);

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

      // 2) 필요 캐릭터 ID만 추려서 Set에 모음
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

      // 6) 최종 MatchModel 리스트 생성
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
