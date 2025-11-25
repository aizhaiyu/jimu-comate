import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/providers/lego_provider.dart';
import 'package:app/models/lego_models.dart';
import 'package:app/models/project_models.dart';
import 'package:app/widgets/lego_workspace.dart';
import 'package:app/widgets/lego_controls.dart';
import 'package:app/widgets/tutorial_overlay.dart';
import 'package:app/services/project_service.dart';

class LegoStudioPage extends ConsumerStatefulWidget {
  final ProjectData? initialProject;
  final bool isTutorialMode;

  const LegoStudioPage({
    super.key,
    this.initialProject,
    this.isTutorialMode = false,
  });

  @override
  ConsumerState<LegoStudioPage> createState() => _LegoStudioPageState();
}

class _LegoStudioPageState extends ConsumerState<LegoStudioPage>
    with WidgetsBindingObserver {
  static final GlobalKey<LegoWorkspaceState> workspaceKey = GlobalKey<LegoWorkspaceState>();
  
  bool _showTutorial = false;
  bool _isCheckingTutorial = true;
  int _previousBrickCount = 0;
  List<BrickData> _savedBricksBeforeTutorial = []; // 教学模式前保存的积木
  bool _isSaving = false; // 保存加载状态
  String? _currentProjectId; // 当前编辑的项目ID（如果是打开已有项目）
  String? _currentProjectName; // 当前项目名称
  List<BrickData> _initialBricks = []; // 进入页面时的初始积木状态
  bool _hasSaved = false; // 标记本次会话是否有保存操作

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 进入积木搭建页面时强制横屏
    _setLandscapeMode();
    
    // 如果是教学模式，保存当前积木并清空
    if (widget.isTutorialMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 保存当前积木状态
        _savedBricksBeforeTutorial = List<BrickData>.from(ref.read(legoProvider).bricks);
        // 清空画布
        ref.read(legoProvider.notifier).clear();
        // 记录初始状态（教学模式初始为空）
        _initialBricks = [];
      });
    } else if (widget.initialProject != null) {
      // 如果有初始项目，从JSON恢复场景
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreProjectFromJson(widget.initialProject!);
        // 初始状态会在恢复完成后保存
      });
    } else {
      // 新建项目：清空画布，开始新的创作
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(legoProvider.notifier).clear();
        // 记录初始状态（新项目初始为空）
        _initialBricks = [];
      });
    }
    
    // 检查是否需要显示新手教学
    _checkTutorial();
  }
  
  void _restoreProjectFromJson(ProjectData project) {
    final legoNotifier = ref.read(legoProvider.notifier);
    
    // 保存项目ID和名称，用于后续更新保存
    _currentProjectId = project.id;
    _currentProjectName = project.name;
    
    // 清空当前场景
    legoNotifier.clear();
    
    // 从JSON恢复积木数据（包含完整属性）
    try {
      for (final brickJson in project.bricks) {
        // 将JSON转换为BrickData对象
        final brick = BrickData.fromJson(brickJson as Map<String, dynamic>);
        // 使用新方法直接添加完整的积木数据
        legoNotifier.addBrickDirect(brick);
      }
      
      // 保存初始状态（恢复后的积木列表）
      _initialBricks = List<BrickData>.from(ref.read(legoProvider).bricks);
      
      // 显示恢复成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '项目"${project.name}"已恢复，包含${project.brickCount}个积木',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 恢复失败提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('项目恢复失败: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
  
  Future<void> _checkTutorial() async {
    // 如果是教学模式，强制显示教学
    if (widget.isTutorialMode) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _showTutorial = true;
          _isCheckingTutorial = false;
        });
      }
      return;
    }
    
    // 正常模式：检查是否需要显示新手教学
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;
    
    // 延迟显示教学，等待3D场景加载
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _showTutorial = !hasSeenTutorial;
        _isCheckingTutorial = false;
      });
    }
  }
  
  Future<void> _completeTutorial() async {
    // 如果不是教学模式，保存状态
    if (!widget.isTutorialMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_tutorial', true);
    }
    
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
      
      // 如果是教学模式，完成后自动退出
      if (widget.isTutorialMode) {
        // 处理教学模式结束时的积木恢复
        _handleTutorialCompletion();
        await Future.delayed(const Duration(milliseconds: 3500)); // 等待祝贺消息显示
        if (mounted) {
          Navigator.of(context).pop(_hasSaved);
        }
      }
    }
  }
  
  Future<void> _skipTutorial() async {
    HapticFeedback.lightImpact();
    
    // 如果不是教学模式，保存状态
    if (!widget.isTutorialMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_tutorial', true);
    }
    
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
      
      // 如果是教学模式，跳过后直接退出
      if (widget.isTutorialMode) {
        _handleTutorialCompletion();
        Navigator.of(context).pop(_hasSaved);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 退出时恢复方向设置
    _restoreOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用恢复时确保横屏模式
      _setLandscapeMode();
    }
  }

  void _setLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreOrientation() async {
    // 保持横屏模式，只恢复状态栏显示
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final legoState = ref.watch(legoProvider);
    final legoNotifier = ref.watch(legoNotifierProvider);
    
    // 监听积木数量变化，当用户成功放置第一块积木后自动完成教学
    if (_showTutorial && legoState.bricks.isNotEmpty && _previousBrickCount == 0) {
      // 用户成功放置了第一块积木！
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeTutorial();
        // 显示鼓励提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.celebration, color: Colors.amber, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 太棒了！你已经掌握了积木搭建的基础操作！',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
    _previousBrickCount = legoState.bricks.length;

    return PopScope(
      canPop: false, // 禁止直接返回
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackPress(); // 调用确认对话框
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Stack(
        children: [
          // 返回按钮（左上角浮动）
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'back_button',
              mini: true,
              backgroundColor: const Color(0xFF1F2937),
              onPressed: () => _handleBackPress(),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          
          // 信息按钮（右上角浮动）
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'info_button',
              mini: true,
              backgroundColor: const Color(0xFF1F2937),
              onPressed: () {
                _showInfo(context);
              },
              child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
          ),
          
          // 3D Workspace - takes full screen
          Positioned.fill(
            child: LegoWorkspace(
              key: workspaceKey,
              bricks: legoState.bricks,
              toolMode: legoState.toolMode,
              selectedShape: legoState.selectedShape,
              selectedColor: legoState.selectedColor,
              rotation: legoState.rotation,
              viewMode: legoState.viewMode,
              showGrid: legoState.showGrid,
              showShadows: legoState.showShadows,
              isPlateMode: legoState.isPlateMode,
              onAddBrick: (brick) => legoNotifier.addBrick(brick.position),
              onRemoveBrick: (id) => legoNotifier.removeBrick(id),
              onPaintBrick: (id) => legoNotifier.paintBrick(id),
              onMoveBrick: (id, position) => legoNotifier.moveBrick(id, position),
            ),
          ),

          // Professional UI Controls
          LegoControls(
            selectedColor: legoState.selectedColor,
            setSelectedColor: legoNotifier.setSelectedColor,
            selectedShape: legoState.selectedShape,
            setSelectedShape: legoNotifier.setSelectedShape,
            toolMode: legoState.toolMode,
            setToolMode: legoNotifier.setToolMode,
            rotation: legoState.rotation,
            onRotate: legoNotifier.rotate,
            onUndo: legoNotifier.undo,
            onRedo: legoNotifier.redo,
            onClear: legoNotifier.clear,
            canUndo: legoNotifier.canUndo,
            canRedo: legoNotifier.canRedo,
            viewMode: legoState.viewMode,
            setViewMode: legoNotifier.setViewMode,
            showGrid: legoState.showGrid,
            setShowGrid: legoNotifier.setShowGrid,
            showShadows: legoState.showShadows,
            setShowShadows: legoNotifier.setShowShadows,
            onExport: () async {
              await _handleSave();
            },
          ),
          
          // 新手教学覆盖层
          if (_showTutorial && !_isCheckingTutorial)
            TutorialOverlay(
              onComplete: _completeTutorial,
              onSkip: _skipTutorial,
            ),
        ],
      ),
      ),
    );
  }
  
  // 处理教学模式结束时的积木恢复
  void _handleTutorialCompletion() {
    if (widget.isTutorialMode && _savedBricksBeforeTutorial.isNotEmpty) {
      // 使用 addPostFrameCallback 确保 ref 在下一帧仍然有效
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(legoProvider.notifier).addToHistory(_savedBricksBeforeTutorial);
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return; // 防止重复保存
    
    final legoState = ref.read(legoProvider);
    
    // 检查是否有积木
    if (legoState.bricks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有积木可以保存'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 使用项目服务保存到项目管理系统
      final success = await _saveAsProject(legoState.bricks);
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      if (success) {
        // 保存成功后，更新初始状态为当前状态
        _initialBricks = List<BrickData>.from(legoState.bricks);
        _hasSaved = true; // 标记已保存
        _showSaveSuccessDialog('', legoState.bricks.length);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存到项目失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<bool> _saveAsProject(List<BrickData> bricks) async {
    try {
      // 导入项目服务
      final projectService = ProjectService();
      await projectService.init();
      
      // 将 BrickData 对象转换为 JSON (正确的保存格式)
      final bricksJson = bricks.map((brick) => brick.toJson()).toList();
      
      final ProjectData project;
      
      if (_currentProjectId != null) {
        // 更新已有项目
        final existingProject = await projectService.getProjectById(_currentProjectId!);
        if (existingProject != null) {
          project = existingProject.copyWith(
            bricks: bricksJson,
            updatedAt: DateTime.now(),
            brickCount: bricks.length,
          );
        } else {
          // 项目不存在，创建新项目
          final now = DateTime.now();
          project = ProjectData.create(
            _currentProjectName ?? 'LEGO作品_${now.month}月${now.day}日${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            bricksJson,
          );
          _currentProjectId = project.id;
        }
      } else {
        // 创建新项目
        final now = DateTime.now();
        project = ProjectData.create(
          'LEGO作品_${now.month}月${now.day}日${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          bricksJson,
        );
        // 保存新项目的ID，下次保存时更新而不是新建
        _currentProjectId = project.id;
        _currentProjectName = project.name;
      }
      
      // 保存项目
      final success = await projectService.saveProject(project);
      return success;
      
    } catch (e) {
      print('保存项目失败: $e');
      return false;
    }
  }
  void _showSaveSuccessDialog(String filePath, int brickCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.2), // 改为蓝色
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF3B82F6), // 改为蓝色
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              ' 作品已保存',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎨 已保存 $brickCount 个积木',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1), // 改为蓝色
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3), // 改为蓝色
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade300, // 使用正确的蓝色调
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '💡 您可以在"我的作品"中继续编辑', // 简化提示，去掉JSON相关内容
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '好的',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              _restoreOrientation();
              Navigator.of(context).pop(true); // 退出编辑页面并返回true表示已保存
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.2),
            ),
            child: const Text(
              '退出',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 检测是否有未保存的修改
  bool _hasUnsavedChanges(List<BrickData> currentBricks) {
    // 数量不同，肯定有修改
    if (currentBricks.length != _initialBricks.length) {
      return true;
    }
    
    // 数量相同，检查每个积木的内容
    for (int i = 0; i < currentBricks.length; i++) {
      final current = currentBricks[i];
      final initial = _initialBricks[i];
      
      // 检查位置、颜色、尺寸、旋转等属性
      if (current.position.toString() != initial.position.toString() ||
          current.color != initial.color ||
          current.size.toString() != initial.size.toString() ||
          current.rotation != initial.rotation ||
          current.hasWheels != initial.hasWheels) {
        return true;
      }
    }
    
    // 完全相同，没有修改
    return false;
  }

  // 处理返回按钮 - 检测是否有修改，有修改才弹出确认对话框
  void _handleBackPress() {
    HapticFeedback.lightImpact();
    final legoState = ref.read(legoProvider);
    
    // 教学模式直接返回
    if (widget.isTutorialMode) {
      _handleTutorialCompletion();
      _restoreOrientation();
      Navigator.of(context).pop(_hasSaved);
      return;
    }
    
    // 检测是否有修改
    final hasChanges = _hasUnsavedChanges(legoState.bricks);
    
    // 没有修改，直接返回
    if (!hasChanges) {
      _restoreOrientation();
      Navigator.of(context).pop(_hasSaved);
      return;
    }
    
    // 有修改时，显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 12),
            Text(
              '确认退出？',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '当前有 ${legoState.bricks.length} 个积木，退出前请确保已保存作品。',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '继续编辑',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              _restoreOrientation();
              Navigator.of(context).pop(_hasSaved); // 返回主页，同时返回保存状态
            },
            child: const Text(
              '退出',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          '操作提示',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 拖拽积木：从左侧积木库拖拽到画布\n'
              '🔄 旋转：点击旋转按钮或拖拽视角\n'
              '🎨 上色：选择上色工具点击积木\n'
              '🗑️ 删除：选择擦除工具点击积木\n'
              '↩️ 撤销：支持撤销操作\n'
              '📷 分享：点击分享按钮保存作品',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                // 重置教学状态，再次显示
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_tutorial', false);
                setState(() {
                  _showTutorial = true;
                });
              },
              icon: const Icon(Icons.replay, color: Color(0xFF3B82F6), size: 18),
              label: const Text(
                '重新播放新手教学',
                style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '知道了',
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}