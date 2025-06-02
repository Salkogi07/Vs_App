// lib/models/character.dart

class Character {
  final String id;
  final String name;
  final String avatarUrl;
  final String attributes; // 예시로 “속성”을 문자열 형태로 저장

  Character({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.attributes,
  });

  factory Character.fromMap(Map<String, dynamic> m) {
    return Character(
      id: m['id'] as String,
      name: m['name'] as String,
      avatarUrl: m['avatar_url'] as String? ?? '',
      attributes: m['attributes'] as String? ?? '',
    );
  }
}
