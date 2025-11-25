import 'package:flutter/material.dart';
import 'package:app/models/lego_models.dart';

/// 应用主题模式枚举
enum AppThemeMode { system, light, dark }

/// 应用设置数据模型
class SettingsData {
  final ThemeMode themeMode;
  final double autoSaveInterval; // 自动保存间隔（分钟）
  final bool enableAutoSave;
  final bool enableSoundEffects;
  final bool enableHapticFeedback;
  final String defaultBrickColor;
  final BrickShape defaultBrickShape;
  final bool showGridByDefault;
  final bool showShadowsByDefault;
  final double cameraRotationSpeed;
  final double cameraZoomSpeed;
  final String language; // 系统语言
  final bool enableTutorial;
  final int maxHistorySteps; // 最大历史记录步数

  const SettingsData({
    this.themeMode = ThemeMode.system,
    this.autoSaveInterval = 5.0,
    this.enableAutoSave = true,
    this.enableSoundEffects = true,
    this.enableHapticFeedback = true,
    this.defaultBrickColor = '#ef4444',
    this.defaultBrickShape = const BrickShape(id: '2x4', name: '2x4', size: [2, 1, 4]),
    this.showGridByDefault = true,
    this.showShadowsByDefault = true,
    this.cameraRotationSpeed = 1.0,
    this.cameraZoomSpeed = 1.0,
    this.language = 'zh_CN',
    this.enableTutorial = true,
    this.maxHistorySteps = 50,
  });

  SettingsData copyWith({
    ThemeMode? themeMode,
    double? autoSaveInterval,
    bool? enableAutoSave,
    bool? enableSoundEffects,
    bool? enableHapticFeedback,
    String? defaultBrickColor,
    BrickShape? defaultBrickShape,
    bool? showGridByDefault,
    bool? showShadowsByDefault,
    double? cameraRotationSpeed,
    double? cameraZoomSpeed,
    String? language,
    bool? enableTutorial,
    int? maxHistorySteps,
  }) {
    return SettingsData(
      themeMode: themeMode ?? this.themeMode,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableAutoSave: enableAutoSave ?? this.enableAutoSave,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      defaultBrickColor: defaultBrickColor ?? this.defaultBrickColor,
      defaultBrickShape: defaultBrickShape ?? this.defaultBrickShape,
      showGridByDefault: showGridByDefault ?? this.showGridByDefault,
      showShadowsByDefault: showShadowsByDefault ?? this.showShadowsByDefault,
      cameraRotationSpeed: cameraRotationSpeed ?? this.cameraRotationSpeed,
      cameraZoomSpeed: cameraZoomSpeed ?? this.cameraZoomSpeed,
      language: language ?? this.language,
      enableTutorial: enableTutorial ?? this.enableTutorial,
      maxHistorySteps: maxHistorySteps ?? this.maxHistorySteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'autoSaveInterval': autoSaveInterval,
      'enableAutoSave': enableAutoSave,
      'enableSoundEffects': enableSoundEffects,
      'enableHapticFeedback': enableHapticFeedback,
      'defaultBrickColor': defaultBrickColor,
      'defaultBrickShape': defaultBrickShape.id,
      'showGridByDefault': showGridByDefault,
      'showShadowsByDefault': showShadowsByDefault,
      'cameraRotationSpeed': cameraRotationSpeed,
      'cameraZoomSpeed': cameraZoomSpeed,
      'language': language,
      'enableTutorial': enableTutorial,
      'maxHistorySteps': maxHistorySteps,
    };
  }

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      autoSaveInterval: json['autoSaveInterval']?.toDouble() ?? 5.0,
      enableAutoSave: json['enableAutoSave'] ?? true,
      enableSoundEffects: json['enableSoundEffects'] ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      defaultBrickColor: json['defaultBrickColor'] ?? '#ef4444',
      defaultBrickShape: const BrickShape(id: '2x4', name: '2x4', size: [2, 1, 4]),
      showGridByDefault: json['showGridByDefault'] ?? true,
      showShadowsByDefault: json['showShadowsByDefault'] ?? true,
      cameraRotationSpeed: json['cameraRotationSpeed']?.toDouble() ?? 1.0,
      cameraZoomSpeed: json['cameraZoomSpeed']?.toDouble() ?? 1.0,
      language: json['language'] ?? 'zh_CN',
      enableTutorial: json['enableTutorial'] ?? true,
      maxHistorySteps: json['maxHistorySteps'] ?? 50,
    );
  }
}

class SettingsCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  const SettingsCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
