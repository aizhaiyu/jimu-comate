import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/providers/settings_provider.dart';
import 'package:app/models/settings_models.dart';
import 'package:app/constants/lego_constants.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF111827),
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? screenWidth * 0.03 : screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: isLandscape ? _buildLandscapeLayout(settings, screenWidth, screenHeight) 
                               : _buildPortraitLayout(settings, screenWidth, screenHeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(SettingsData settings, double screenWidth, double screenHeight) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildGeneralSettings(settings),
                const SizedBox(height: 16),
                _buildAppearanceSettings(settings),
                const SizedBox(height: 16),
                _buildBehaviorSettings(settings),
                const SizedBox(height: 16),
                _buildControlSettings(settings),
                const SizedBox(height: 16),
                _buildStorageSettings(settings),
                const SizedBox(height: 16),
                _buildAboutSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(SettingsData settings, double screenWidth, double screenHeight) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCompactGeneralSettings(settings),
                      const SizedBox(height: 12),
                      _buildCompactAppearanceSettings(settings),
                      const SizedBox(height: 12),
                      _buildCompactBehaviorSettings(settings),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCompactControlSettings(settings),
                      const SizedBox(height: 12),
                      _buildCompactStorageSettings(settings),
                      const SizedBox(height: 12),
                      _buildCompactAboutSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactGeneralSettings(SettingsData settings) {
    return _buildCompactSettingsSection(
      title: '通用设置',
      icon: Icons.settings,
      color: const Color(0xFF3B82F6),
      children: [
        _buildCompactSettingItem(
          title: '语言',
          subtitle: '选择应用界面语言',
          trailing: _buildLanguageSelector(settings.language),
          onTap: () => _showLanguageSelector(),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '音效',
          subtitle: '操作音效开关',
          trailing: Switch(
            value: settings.enableSoundEffects,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableSoundEffects(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '触感反馈',
          subtitle: '振动反馈开关',
          trailing: Switch(
            value: settings.enableHapticFeedback,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableHapticFeedback(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '新手教程',
          subtitle: '首次使用时显示教程',
          trailing: Switch(
            value: settings.enableTutorial,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableTutorial(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAppearanceSettings(SettingsData settings) {
    return _buildCompactSettingsSection(
      title: '外观设置',
      icon: Icons.palette,
      color: const Color(0xFF8B5CF6),
      children: [
        _buildCompactSettingItem(
          title: '主题模式',
          subtitle: '选择界面主题',
          trailing: _buildThemeModeSelector(settings.themeMode),
          onTap: () => _showThemeModeSelector(),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '默认显示网格',
          subtitle: '新建项目时默认显示网格',
          trailing: Switch(
            value: settings.showGridByDefault,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateShowGridByDefault(value);
            },
            activeColor: const Color(0xFF8B5CF6),
          ),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '默认显示阴影',
          subtitle: '新建项目时默认显示阴影',
          trailing: Switch(
            value: settings.showShadowsByDefault,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateShowShadowsByDefault(value);
            },
            activeColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBehaviorSettings(SettingsData settings) {
    return _buildCompactSettingsSection(
      title: '行为设置',
      icon: Icons.psychology,
      color: const Color(0xFF10B981),
      children: [
        _buildCompactSettingItem(
          title: '默认积木颜色',
          subtitle: '新积木的默认颜色',
          trailing: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(int.parse(settings.defaultBrickColor.replaceFirst('#', '0xFF'))),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          onTap: () => _showColorSelector(),
        ),
      ],
    );
  }

  Widget _buildCompactControlSettings(SettingsData settings) {
    return _buildCompactSettingsSection(
      title: '控制设置',
      icon: Icons.gamepad,
      color: const Color(0xFFF59E0B),
      children: [
        _buildCompactSettingItem(
          title: '相机旋转速度',
          subtitle: '调整3D视角旋转速度',
          trailing: _buildCompactSpeedSlider(
            value: settings.cameraRotationSpeed,
            onChanged: (value) {
              ref.read(settingsNotifierProvider).updateCameraRotationSpeed(value);
            },
          ),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '相机缩放速度',
          subtitle: '调整3D视角缩放速度',
          trailing: _buildCompactSpeedSlider(
            value: settings.cameraZoomSpeed,
            onChanged: (value) {
              ref.read(settingsNotifierProvider).updateCameraZoomSpeed(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStorageSettings(SettingsData settings) {
    return _buildCompactSettingsSection(
      title: '存储设置',
      icon: Icons.storage,
      color: const Color(0xFFEF4444),
      children: [
        _buildCompactSettingItem(
          title: '自动保存',
          subtitle: '编辑时自动保存作品',
          trailing: Switch(
            value: settings.enableAutoSave,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableAutoSave(value);
            },
            activeColor: const Color(0xFFEF4444),
          ),
        ),
        if (settings.enableAutoSave) ...[
          _buildCompactDivider(),
          _buildCompactSettingItem(
            title: '自动保存间隔',
            subtitle: '${settings.autoSaveInterval.toInt()} 分钟',
            trailing: Container(
              width: 80,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFEF4444),
                  thumbColor: const Color(0xFFEF4444),
                  overlayColor: const Color(0xFFEF4444).withOpacity(0.2),
                ),
                child: Slider(
                  value: settings.autoSaveInterval,
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  onChanged: (value) {
                    ref.read(settingsNotifierProvider).updateAutoSaveInterval(value);
                  },
                ),
              ),
            ),
          ),
        ],
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '最大历史记录',
          subtitle: '${settings.maxHistorySteps} 步',
          trailing: Container(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFEF4444),
                thumbColor: const Color(0xFFEF4444),
                overlayColor: const Color(0xFFEF4444).withOpacity(0.2),
              ),
              child: Slider(
                value: settings.maxHistorySteps.toDouble(),
                min: 10.0,
                max: 100.0,
                divisions: 9,
                onChanged: (value) {
                  ref.read(settingsNotifierProvider).updateMaxHistorySteps(value.toInt());
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAboutSection() {
    return _buildCompactSettingsSection(
      title: '关于',
      icon: Icons.info,
      color: const Color(0xFF6B7280),
      children: [
        _buildCompactSettingItem(
          title: '版本',
          subtitle: '1.0.0',
          trailing: const Icon(
            Icons.info_outline,
            color: Colors.white54,
            size: 16,
          ),
        ),
        _buildCompactDivider(),
        _buildCompactSettingItem(
          title: '开发者',
          subtitle: '广州梦之池科技有限公司',
          trailing: const Icon(
            Icons.people,
            color: Colors.white54,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompactSettingItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildCompactSpeedSlider({
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      width: 80,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: value,
          min: 0.5,
          max: 2.0,
          divisions: 3,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '设置',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showResetDialog(),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(SettingsData settings) {
    return _buildSettingsSection(
      title: '通用设置',
      icon: Icons.settings,
      color: const Color(0xFF3B82F6),
      children: [
        _buildSettingItem(
          title: '语言',
          subtitle: '选择应用界面语言',
          trailing: _buildLanguageSelector(settings.language),
          onTap: () => _showLanguageSelector(),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '音效',
          subtitle: '操作音效开关',
          trailing: Switch(
            value: settings.enableSoundEffects,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableSoundEffects(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '触感反馈',
          subtitle: '振动反馈开关',
          trailing: Switch(
            value: settings.enableHapticFeedback,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableHapticFeedback(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '新手教程',
          subtitle: '首次使用时显示教程',
          trailing: Switch(
            value: settings.enableTutorial,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableTutorial(value);
            },
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings(SettingsData settings) {
    return _buildSettingsSection(
      title: '外观设置',
      icon: Icons.palette,
      color: const Color(0xFF8B5CF6),
      children: [
        _buildSettingItem(
          title: '主题模式',
          subtitle: '选择界面主题',
          trailing: _buildThemeModeSelector(settings.themeMode),
          onTap: () => _showThemeModeSelector(),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '默认显示网格',
          subtitle: '新建项目时默认显示网格',
          trailing: Switch(
            value: settings.showGridByDefault,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateShowGridByDefault(value);
            },
            activeColor: const Color(0xFF8B5CF6),
          ),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '默认显示阴影',
          subtitle: '新建项目时默认显示阴影',
          trailing: Switch(
            value: settings.showShadowsByDefault,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateShowShadowsByDefault(value);
            },
            activeColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorSettings(SettingsData settings) {
    return _buildSettingsSection(
      title: '行为设置',
      icon: Icons.psychology,
      color: const Color(0xFF10B981),
      children: [
        _buildSettingItem(
          title: '默认积木颜色',
          subtitle: '新积木的默认颜色',
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(int.parse(settings.defaultBrickColor.replaceFirst('#', '0xFF'))),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          onTap: () => _showColorSelector(),
        ),
      ],
    );
  }

  Widget _buildControlSettings(SettingsData settings) {
    return _buildSettingsSection(
      title: '控制设置',
      icon: Icons.gamepad,
      color: const Color(0xFFF59E0B),
      children: [
        _buildSettingItem(
          title: '相机旋转速度',
          subtitle: '调整3D视角旋转速度',
          trailing: _buildSpeedSlider(
            value: settings.cameraRotationSpeed,
            onChanged: (value) {
              ref.read(settingsNotifierProvider).updateCameraRotationSpeed(value);
            },
          ),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '相机缩放速度',
          subtitle: '调整3D视角缩放速度',
          trailing: _buildSpeedSlider(
            value: settings.cameraZoomSpeed,
            onChanged: (value) {
              ref.read(settingsNotifierProvider).updateCameraZoomSpeed(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSettings(SettingsData settings) {
    return _buildSettingsSection(
      title: '存储设置',
      icon: Icons.storage,
      color: const Color(0xFFEF4444),
      children: [
        _buildSettingItem(
          title: '自动保存',
          subtitle: '编辑时自动保存作品',
          trailing: Switch(
            value: settings.enableAutoSave,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(settingsNotifierProvider).updateEnableAutoSave(value);
            },
            activeColor: const Color(0xFFEF4444),
          ),
        ),
        if (settings.enableAutoSave) ...[
          _buildDivider(),
          _buildSettingItem(
            title: '自动保存间隔',
            subtitle: '${settings.autoSaveInterval.toInt()} 分钟',
            trailing: Container(
              width: 100,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFEF4444),
                  thumbColor: const Color(0xFFEF4444),
                  overlayColor: const Color(0xFFEF4444).withOpacity(0.2),
                ),
                child: Slider(
                  value: settings.autoSaveInterval,
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  onChanged: (value) {
                    ref.read(settingsNotifierProvider).updateAutoSaveInterval(value);
                  },
                ),
              ),
            ),
          ),
        ],
        _buildDivider(),
        _buildSettingItem(
          title: '最大历史记录',
          subtitle: '${settings.maxHistorySteps} 步',
          trailing: Container(
            width: 100,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFEF4444),
                thumbColor: const Color(0xFFEF4444),
                overlayColor: const Color(0xFFEF4444).withOpacity(0.2),
              ),
              child: Slider(
                value: settings.maxHistorySteps.toDouble(),
                min: 10.0,
                max: 100.0,
                divisions: 9,
                onChanged: (value) {
                  ref.read(settingsNotifierProvider).updateMaxHistorySteps(value.toInt());
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: '关于',
      icon: Icons.info,
      color: const Color(0xFF6B7280),
      children: [
        _buildSettingItem(
          title: '版本',
          subtitle: '1.0.0',
          trailing: const Icon(
            Icons.info_outline,
            color: Colors.white54,
            size: 20,
          ),
        ),
        _buildDivider(),
        _buildSettingItem(
          title: '开发者',
          subtitle: '广州梦之池科技有限公司',
          trailing: const Icon(
            Icons.people,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildLanguageSelector(String currentLanguage) {
    final language = languageOptions.firstWhere(
      (lang) => lang['code'] == currentLanguage,
      orElse: () => languageOptions[0],
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        language['name'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(ThemeMode currentMode) {
    final theme = themeModeOptions.firstWhere(
      (theme) => theme['value'] == currentMode,
      orElse: () => themeModeOptions[0],
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        theme['name'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSpeedSlider({
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      width: 100,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          value: value,
          min: 0.5,
          max: 2.0,
          divisions: 3,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择语言',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: languageOptions.map((language) {
                  final isSelected = ref.read(settingsProvider).language == language['code'];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(settingsNotifierProvider).updateLanguage(language['code'] as String);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                language['name'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择主题',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: themeModeOptions.map((theme) {
                  final mode = theme['value'] as ThemeMode;
                  final isSelected = ref.read(settingsProvider).themeMode == mode;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(settingsNotifierProvider).updateThemeMode(mode);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getThemeIcon(mode),
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                theme['name'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择默认积木颜色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: LegoConstants.brickColors.length,
                itemBuilder: (context, index) {
                  final color = LegoConstants.brickColors[index];
                  final isSelected = color.value == ref.read(settingsProvider).defaultBrickColor;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(settingsNotifierProvider).updateDefaultBrickColor(color.value);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.value.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(int.parse(color.value.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                color.name,
                                style: TextStyle(
                                  color: _getContrastColor(color.value),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          '重置设置',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '确定要重置所有设置到默认值吗？此操作不可撤销。',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsNotifierProvider).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已重置'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.settings_brightness;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  Color _getContrastColor(String colorValue) {
    final color = Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// 语言选项
final List<Map<String, dynamic>> languageOptions = [
  {'code': 'zh', 'name': '简体中文'},
  {'code': 'en', 'name': 'English'},
  {'code': 'ja', 'name': '日本語'},
];

// 主题选项
final List<Map<String, dynamic>> themeModeOptions = [
  {'name': '跟随系统', 'value': ThemeMode.system},
  {'name': '浅色模式', 'value': ThemeMode.light},
  {'name': '深色模式', 'value': ThemeMode.dark},
];