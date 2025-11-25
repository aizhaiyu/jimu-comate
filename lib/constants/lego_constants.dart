import 'package:app/models/lego_models.dart';

class LegoConstants {
  static const double brickUnit = 1.0; // Base size of 1 stud width
  static const double brickHeight = 1.2; // Height of a standard brick relative to width

  static const List<ColorDef> brickColors = [
    ColorDef(name: '红色', value: '#ef4444'),
    ColorDef(name: '蓝色', value: '#3b82f6'),
    ColorDef(name: '绿色', value: '#22c55e'),
    ColorDef(name: '黄色', value: '#eab308'),
    ColorDef(name: '橙色', value: '#f97316'),
    ColorDef(name: '紫色', value: '#a855f7'),
    ColorDef(name: '白色', value: '#f3f4f6'),
    ColorDef(name: '灰色', value: '#6b7280'),
    ColorDef(name: '黑色', value: '#1f2937'),
    ColorDef(name: '粉色', value: '#ec4899'),
    ColorDef(name: '青色', value: '#06b6d4'),
    ColorDef(name: '柠檬绿', value: '#84cc16'),
  ];

  static const List<BrickShape> brickShapes = [
    // 基础积木
    BrickShape(id: '1x1', name: '1x1', size: [1, 1, 1]),
    BrickShape(id: '2x1', name: '2x1', size: [2, 1, 1]),
    BrickShape(id: '3x1', name: '3x1', size: [3, 1, 1]),
    BrickShape(id: '4x1', name: '4x1', size: [4, 1, 1]),
    BrickShape(id: '2x2', name: '2x2', size: [2, 1, 2]),
    BrickShape(id: '2x3', name: '2x3', size: [2, 1, 3]),
    BrickShape(id: '2x4', name: '2x4', size: [2, 1, 4]),
    BrickShape(id: '4x4', name: '4x4', size: [4, 1, 4]),
    // 运动积木（带轮子）
    BrickShape(id: '2x4-wheel', name: '2x4🚗', size: [2, 1, 4], hasWheels: true),
    BrickShape(id: '2x3-wheel', name: '2x3🚗', size: [2, 1, 3], hasWheels: true),
    BrickShape(id: '2x2-wheel', name: '2x2🚗', size: [2, 1, 2], hasWheels: true),
    BrickShape(id: '4x4-wheel', name: '4x4🚙', size: [4, 1, 4], hasWheels: true),
  ];
}