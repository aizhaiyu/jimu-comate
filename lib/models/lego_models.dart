enum ToolMode { build, paint, erase, view, inspect }
enum ViewMode { editor, preview }

class BrickShape {
  final String id;
  final String name;
  final List<int> size; // [width, height, depth]
  final bool hasWheels; // 是否带轮子

  const BrickShape({
    required this.id,
    required this.name,
    required this.size,
    this.hasWheels = false,
  });
}

class BrickData {
  final String id;
  final List<double> position; // [x, y, z]
  final String color;
  final List<num> size; // [width, height, depth] - num支持整数和小数
  final int rotation; // 0-3
  final bool hasWheels; // 是否带轮子

  const BrickData({
    required this.id,
    required this.position,
    required this.color,
    required this.size,
    required this.rotation,
    this.hasWheels = false,
  });

  BrickData copyWith({
    String? id,
    List<double>? position,
    String? color,
    List<num>? size,
    int? rotation,
    bool? hasWheels,
  }) {
    return BrickData(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      hasWheels: hasWheels ?? this.hasWheels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'color': color,
      'size': size,
      'rotation': rotation,
      'hasWheels': hasWheels,
    };
  }

  factory BrickData.fromJson(Map<String, dynamic> json) {
    return BrickData(
      id: json['id'],
      position: List<double>.from(json['position']),
      color: json['color'],
      size: List<num>.from(json['size']),
      rotation: json['rotation'],
      hasWheels: json['hasWheels'] ?? false,
    );
  }
}

class ColorDef {
  final String name;
  final String value; // Hex

  const ColorDef({
    required this.name,
    required this.value,
  });
}