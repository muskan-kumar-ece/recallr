class NetworkCategory {
  final String id;
  final String name;
  final int color;
  final String icon;
  final int order;
  const NetworkCategory(
      {required this.id,
      required this.name,
      this.color = 0xFF7C3AED,
      this.icon = 'folder',
      this.order = 0});

  factory NetworkCategory.fromMap(String id, Map<String, dynamic> data) =>
      NetworkCategory(
          id: id,
          name: data['name'] as String? ?? '',
          color: (data['color'] as num?)?.toInt() ?? 0xFF7C3AED,
          icon: data['icon'] as String? ?? 'folder',
          order: (data['order'] as num?)?.toInt() ?? 0);

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'normalizedName': name.trim().toLowerCase(),
        'color': color,
        'icon': icon,
        'order': order
      };
}
