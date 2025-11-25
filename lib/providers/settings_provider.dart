import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:app/models/settings_models.dart';
import 'package:app/models/lego_models.dart';

class SettingsNotifier extends StateNotifier<SettingsData> {
  SettingsNotifier() : super(const SettingsData()) {
    _loadSettings();
  }

  static const String _settingsKey = 'lego_settings';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        state = SettingsData.fromJson(settingsMap);
      }
    } catch (e) {
      // 如果加载失败，使用默认设置
      print('加载设置失败: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(state.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('保存设置失败: $e');
    }
  }

  void updateThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    _saveSettings();
  }

  void updateAutoSaveInterval(double interval) {
    state = state.copyWith(autoSaveInterval: interval);
    _saveSettings();
  }

  void updateEnableAutoSave(bool enable) {
    state = state.copyWith(enableAutoSave: enable);
    _saveSettings();
  }

  void updateEnableSoundEffects(bool enable) {
    state = state.copyWith(enableSoundEffects: enable);
    _saveSettings();
  }

  void updateEnableHapticFeedback(bool enable) {
    state = state.copyWith(enableHapticFeedback: enable);
    _saveSettings();
  }

  void updateDefaultBrickColor(String color) {
    state = state.copyWith(defaultBrickColor: color);
    _saveSettings();
  }

  void updateDefaultBrickShape(BrickShape shape) {
    state = state.copyWith(defaultBrickShape: shape);
    _saveSettings();
  }

  void updateShowGridByDefault(bool show) {
    state = state.copyWith(showGridByDefault: show);
    _saveSettings();
  }

  void updateShowShadowsByDefault(bool show) {
    state = state.copyWith(showShadowsByDefault: show);
    _saveSettings();
  }

  void updateCameraRotationSpeed(double speed) {
    state = state.copyWith(cameraRotationSpeed: speed);
    _saveSettings();
  }

  void updateCameraZoomSpeed(double speed) {
    state = state.copyWith(cameraZoomSpeed: speed);
    _saveSettings();
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
    _saveSettings();
  }

  void updateEnableTutorial(bool enable) {
    state = state.copyWith(enableTutorial: enable);
    _saveSettings();
  }

  void updateMaxHistorySteps(int steps) {
    state = state.copyWith(maxHistorySteps: steps);
    _saveSettings();
  }

  void resetToDefaults() {
    state = const SettingsData();
    _saveSettings();
  }
}

// Providers
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsData>((ref) {
  return SettingsNotifier();
});

final settingsNotifierProvider = Provider<SettingsNotifier>((ref) {
  return ref.watch(settingsProvider.notifier);
});

// 设置分类
final settingsCategories = [
  const SettingsCategory(
    id: 'general',
    name: '通用设置',
    icon: Icons.settings,
    description: '基本应用设置',
  ),
  const SettingsCategory(
    id: 'appearance',
    name: '外观设置',
    icon: Icons.palette,
    description: '主题和显示选项',
  ),
  const SettingsCategory(
    id: 'behavior',
    name: '行为设置',
    icon: Icons.psychology,
    description: '积木搭建行为',
  ),
  const SettingsCategory(
    id: 'controls',
    name: '控制设置',
    icon: Icons.gamepad,
    description: '相机和控制选项',
  ),
  const SettingsCategory(
    id: 'storage',
    name: '存储设置',
    icon: Icons.storage,
    description: '保存和历史记录',
  ),
  const SettingsCategory(
    id: 'about',
    name: '关于',
    icon: Icons.info,
    description: '应用信息',
  ),
];

// 语言选项
final languageOptions = [
  {'code': 'zh_CN', 'name': '简体中文'},
  {'code': 'zh_TW', 'name': '繁體中文'},
  {'code': 'en_US', 'name': 'English'},
  {'code': 'ja_JP', 'name': '日本語'},
];

// 主题模式选项
final themeModeOptions = [
  {'value': ThemeMode.system, 'name': '跟随系统'},
  {'value': ThemeMode.light, 'name': '浅色主题'},
  {'value': ThemeMode.dark, 'name': '深色主题'},
];
