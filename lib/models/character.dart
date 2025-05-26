class Character {
  final String id;
  final String name;
  final String avatarUrl;

  Character({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory Character.fromMap(Map<String, dynamic> m) => Character(
    id: m['id'],
    name: m['name'],
    avatarUrl: m['avatar_url'] ?? '',
  );
}
