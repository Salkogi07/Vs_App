// lib/services/supabase_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/match_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  /// 1) 이미지 업로드: Mobile ↔ Web 분기
  ///    - file: 로컬 File 객체 (웹에서는 File.fromRawPath(bytes)로 래핑하여 전달)
  ///    - 리턴값: Public URL 문자열 (Storage > Public 버킷에 올리고 getPublicUrl)
  Future<String> uploadAvatar(File file) async {
    final String ext = file.path.split('.').last; // 확장자 추출 (png, jpg 등)
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = 'avatars/$fileName.$ext';

    String fullPath;
    try {
      if (kIsWeb) {
        // ── 웹 환경: File 대신 bytes를 사용
        final bytes = await file.readAsBytes();
        fullPath = await _db.storage
            .from('avatars')
            .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        // uploadBinary 호출 시 실패하면 PostgrestException이 던져짐
      } else {
        // ── 모바일(iOS/Android) 환경: File 객체를 직접 upload
        fullPath = await _db.storage
            .from('avatars')
            .upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        // upload 호출 시 실패하면 PostgrestException이 던져짐
      }

      // Public 버킷이므로 getPublicUrl 호출
      final publicUrl = _db.storage.from('avatars').getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      // 예외가 던져졌다는 것은 업로드 실패를 의미
      rethrow;
    }
  }

  /// 2) 캐릭터 생성: 이름(name), avatarUrl, attributes(속성)을 DB에 저장
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
      // v2에서는 insert 후 반환값을 쓰려면 .select()를 붙여야 하지만,
      // 여기서는 반환 데이터가 필요 없으므로 바로 await만 수행합니다.
    } catch (e) {
      // insert 도중 PostgrestException 등이 던져짐
      rethrow;
    }
  }

  /// 3) 캐릭터 리스트 조회: name ILIKE '%keyword%' 속성 검색
  Future<List<Character>> fetchCharacters({String keyword = ''}) async {
    try {
      // 1) 기본 쿼리: 'characters' 테이블을 select
      PostgrestFilterBuilder query = _db.from('characters').select();

      // 2) 키워드가 있으면 ILIKE 조건 추가
      if (keyword.isNotEmpty) {
        // v2 문법: filter(column, operator, value)
        query = query.filter('name', 'ilike', '%$keyword%');
      }

      // 3) (원한다면) created_at 기준 내림차순 정렬
      //    query = query.order('created_at', ascending: false);

      // 4) 실제 쿼리 실행 (await 결과가 바로 List<dynamic> 형태로 반환)
      final List<dynamic> raw = await query;

      // 5) 맵 자료형을 Character 모델로 변환
      return raw
          .map((e) => Character.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // select 실패 시 PostgrestException 등이 던져짐
      rethrow;
    }
  }

  /// 4) 단일 캐릭터 조회 (ID로)
  Future<Character?> getCharacterById(String id) async {
    try {
      // maybeSingle() → 데이터가 없으면 null, 있으면 Map<String, dynamic> 반환
      final Map<String, dynamic>? raw = await _db
          .from('characters')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (raw == null) {
        return null; // ID에 해당하는 캐릭터가 없을 때
      }
      return Character.fromMap(raw);
    } catch (e) {
      // 조회 중 에러 발생 시
      rethrow;
    }
  }

  /// 5) 매치 생성: charA, charB, startAt, endAt을 DB에 insert
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
        // Supabase는 UTC 기준 ISO8601 문자열이 안전
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 6) 매치 전체 조회 (각 캐릭터 데이터를 불러와 조합)
  Future<List<MatchModel>> fetchMatches() async {
    try {
      // 1) matches 테이블에서 필요한 필드들 select
      final List<dynamic> rawMatches = await _db.from('matches').select();

      // 2) 필요한 캐릭터 ID 목록만 추리기
      final Set<String> charIds = {};
      for (var m in rawMatches) {
        final mm = m as Map<String, dynamic>;
        charIds.add(mm['char_a_id'] as String);
        charIds.add(mm['char_b_id'] as String);
      }

      if (charIds.isEmpty) {
        return [];
      }

      // 3) 캐릭터 ID 목록을 문자열 형태로 "'id1','id2'" → "( 'id1','id2' )" 로 변환
      //    Supabase v2에서는 filter('id','in','(\'id1\',\'id2\')')처럼 문자열로 전달해야 함
      final String inString =
          '(${charIds.map((e) => "'$e'").join(",")})';

      // 4) characters 테이블에서 한 번에 캐릭터 정보 조회
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

      // 6) 최종적으로 MatchModel 리스트 생성
      return rawMatches.map((m) {
        final Map<String, dynamic> mm = m as Map<String, dynamic>;
        final Character ca = charMap[mm['char_a_id'] as String]!;
        final Character cb = charMap[mm['char_b_id'] as String]!;
        return MatchModel.fromMap(mm, ca, cb);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
