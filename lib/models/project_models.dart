class ProjectData {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> bricks; // 改为动态类型以避免循环依赖
  final String thumbnail; // 缩略图路径或base64数据
  final int brickCount;
  final List<String> tags; // 项目标签

  const ProjectData({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.bricks,
    this.thumbnail = '',
    this.brickCount = 0,
    this.tags = const [],
  });

  ProjectData copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? bricks,
    String? thumbnail,
    int? brickCount,
    List<String>? tags,
  }) {
    return ProjectData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bricks: bricks ?? this.bricks,
      thumbnail: thumbnail ?? this.thumbnail,
      brickCount: brickCount ?? this.brickCount,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bricks': bricks,
      'thumbnail': thumbnail,
      'brickCount': bricks.length,
      'tags': tags,
    };
  }

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      bricks: (json['bricks'] as List<dynamic>?) ?? [],
      thumbnail: json['thumbnail'] ?? '',
      brickCount: json['brickCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  factory ProjectData.create(String name, List<dynamic> bricks) {
    final now = DateTime.now();
    return ProjectData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: '创建于${now.year}年${now.month}月${now.day}日',
      createdAt: now,
      updatedAt: now,
      bricks: bricks,
      brickCount: bricks.length,
    );
  }
}

enum ProjectSortMode {
  name,
  dateCreated,
  dateUpdated,
  brickCount,
}

enum ProjectViewMode {
  grid,
  list,
}
