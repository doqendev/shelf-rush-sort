final class ThemeDef {
  const ThemeDef({
    required this.id,
    required this.displayName,
    required this.backgroundColorHex,
    required this.shelfColorHex,
  });

  factory ThemeDef.fromJson(Map<String, Object?> json) {
    return ThemeDef(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      backgroundColorHex: json['backgroundColorHex']! as String,
      shelfColorHex: json['shelfColorHex']! as String,
    );
  }

  final String id;
  final String displayName;
  final String backgroundColorHex;
  final String shelfColorHex;
}
