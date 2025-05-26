import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/match_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  /// 1) 이미지 업로드
  Future<String> uploadAvatar(File file) async {
    final path = 'avatars/${DateTime.now().millisecondsSinceEpoch}.png';

    // 업로드 결과만 StorageResponse 로 받아 error 체크
    final storageRes = await _db
        .storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: false));

    // getPublicUrl은 String 반환하므로 바로 리턴
    return _db.storage.from('avatars').getPublicUrl(path);
  }

  /// 2) 캐릭터 등록
  Future<void> createCharacter(String name, String avatarUrl) async {
    // 오류 발생 시 PostgrestException이 throw됩니다.
    await _db.from('characters').insert({
      'name': name,
      'avatar_url': avatarUrl,
      'user_id': _db.auth.currentUser!.id,
    });
  }

  /// 3) 캐릭터 검색 (이름으로 부분 일치)
  Future<List<Character>> searchCharacters(String keyword) async {
    final List<dynamic> data = await _db
        .from('characters')
        .select('id, name, avatar_url')
        .ilike('name', '%$keyword%');
    return data
        .map((e) => Character.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 4) 매치 생성
  Future<void> createMatch(
      String aId, String bId, DateTime startAt, DateTime endAt) async {
    await _db.from('matches').insert({
      'character_a': aId,
      'character_b': bId,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    });
  }

  /// 5) 매치 목록 조회 (+조인)
  Future<List<MatchModel>> getMatches() async {
    final List<dynamic> data = await _db.from('matches').select('''
      id,
      start_at,
      end_at,
      character_a:characters(id,name,avatar_url),
      character_b:characters(id,name,avatar_url)
    ''');

    return data.map((raw) {
      final map = raw as Map<String, dynamic>;
      final ca = Character.fromMap(map['character_a']);
      final cb = Character.fromMap(map['character_b']);
      return MatchModel.fromMap(map, ca, cb);
    }).toList();
  }

  /// 6) 매치 수정
  Future<void> updateMatch(
      String id, DateTime startAt, DateTime endAt) async {
    await _db
        .from('matches')
        .update({
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    })
        .eq('id', id);
  }

  /// 7) 매치 삭제
  Future<void> deleteMatch(String id) async {
    await _db.from('matches').delete().eq('id', id);
  }
}
