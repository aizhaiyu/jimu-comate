import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/models/lego_models.dart';
import 'package:app/constants/lego_constants.dart';
import 'package:app/providers/lego_provider.dart';

// Sidebar collapse state providers
final leftCollapsedProvider = StateProvider<bool>((ref) => false);
final rightCollapsedProvider = StateProvider<bool>((ref) => false);

class LegoControls extends ConsumerWidget {
  final String selectedColor;
  final Function(String) setSelectedColor;
  final BrickShape selectedShape;
  final Function(BrickShape) setSelectedShape;
  final ToolMode toolMode;
  final Function(ToolMode) setToolMode;
  final int rotation;
  final VoidCallback onRotate;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final bool canUndo;
  final bool canRedo;
  final ViewMode viewMode;
  final Function(ViewMode) setViewMode;
  final bool showGrid;
  final Function(bool) setShowGrid;
  final bool showShadows;
  final Function(bool) setShowShadows;
  final VoidCallback onExport;

  const LegoControls({
    super.key,
    required this.selectedColor,
    required this.setSelectedColor,
    required this.selectedShape,
    required this.setSelectedShape,
    required this.toolMode,
    required this.setToolMode,
    required this.rotation,
    required this.onRotate,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.canUndo,
    required this.canRedo,
    required this.viewMode,
    required this.setViewMode,
    required this.showGrid,
    required this.setShowGrid,
    required this.showShadows,
    required this.setShowShadows,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Preview mode - minimal UI
    if (viewMode == ViewMode.preview) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        top: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: () => setViewMode(ViewMode.editor),
            icon: const Icon(Icons.build, color: Colors.white, size: 18),
            label: const Text(
              '返回编辑',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      );
    }

    // Editor mode - full UI
    return Stack(
      children: [
        // Top toolbar
        _TopToolbar(onExport: onExport),
        // Left sidebar
        const _LeftSidebar(),
        // Right sidebar
        const _RightSidebar(),
        // Collapse handles overlay
        const _LeftCollapseHandle(),
        const _RightCollapseHandle(),
      ],
    );
  }
}

class _TopToolbar extends ConsumerWidget {
  final VoidCallback onExport;
  
  const _TopToolbar({required this.onExport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final double toolbarH = screenH < 800 ? 48 : 52;
    final double hp = screenW < 1100 ? 12 : 16;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: toolbarH,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          border: Border(bottom: BorderSide(color: Colors.grey.shade700, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hp),
          child: Row(
            children: [
              // Logo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '积木工坊',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Central tools
              _ToolbarTools(toolbarH: toolbarH),
              const Spacer(),
              // Right actions
              _ToolbarActions(onExport: onExport),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarTools extends ConsumerWidget {
  final double toolbarH;
  const _ToolbarTools({required this.toolbarH});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legoState = ref.watch(legoProvider);
    final legoNotifier = ref.watch(legoNotifierProvider);
    return Container(
      height: toolbarH - 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade700, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
          _CompactToolButton(
                      active: legoState.toolMode == ToolMode.build,
                      onPressed: () => legoNotifier.setToolMode(ToolMode.build),
            icon: Icons.construction,
            label: '搭建',
            activeColor: Colors.blue.shade500,
                    ),
          _CompactToolButton(
                      active: legoState.toolMode == ToolMode.paint,
                      onPressed: () => legoNotifier.setToolMode(ToolMode.paint),
            icon: Icons.brush,
            label: '上色',
            activeColor: Colors.green.shade500,
                    ),
          _CompactToolButton(
                      active: legoState.toolMode == ToolMode.erase,
                      onPressed: () => legoNotifier.setToolMode(ToolMode.erase),
            icon: Icons.cleaning_services,
            label: '擦除',
            activeColor: Colors.red.shade500,
          ),
          _CompactToolButton(
            active: legoState.toolMode == ToolMode.view,
            onPressed: () => legoNotifier.setToolMode(ToolMode.view),
            icon: Icons.camera_alt,
            label: '相机',
            activeColor: Colors.purple.shade500,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade600,
            margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
          _HistoryButton(
                      onPressed: legoNotifier.canUndo ? legoNotifier.undo : null,
            icon: Icons.undo,
            isActive: legoNotifier.canUndo,
            tooltip: '撤销 (Ctrl+Z)',
          ),
          const SizedBox(width: 2),
          _HistoryButton(
                      onPressed: legoNotifier.canRedo ? legoNotifier.redo : null,
            icon: Icons.redo,
            isActive: legoNotifier.canRedo,
            tooltip: '重做 (Ctrl+Y)',
                    ),
                  ],
                ),
    );
  }
}

class _ToolbarActions extends ConsumerWidget {
  final VoidCallback onExport;
  
  const _ToolbarActions({required this.onExport});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legoNotifier = ref.watch(legoNotifierProvider);
    return Row(
                children: [
                  IconButton(
                    onPressed: legoNotifier.clear,
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Clear All',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.shade700,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  TextButton.icon(
                    onPressed: () => legoNotifier.setViewMode(ViewMode.preview),
                    icon: const Icon(Icons.visibility, size: 14),
          label: const Text('预览'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text('保存'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade600, // 改为蓝色
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
    );
  }
}

class _LeftSidebar extends ConsumerStatefulWidget {
  const _LeftSidebar();

  @override
  ConsumerState<_LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends ConsumerState<_LeftSidebar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // 更新Tab按钮状态
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final legoNotifier = ref.watch(legoNotifierProvider);

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final double toolbarH = screenH < 800 ? 48.0 : 52.0;
    final double leftW = screenW < 1100 ? 200.0 : 256.0;
    final bool collapsed = ref.watch(leftCollapsedProvider);
    const double collapsedW = 44.0;

    // 分离基础积木和运动积木
    final basicShapes = LegoConstants.brickShapes.where((s) => !s.hasWheels).toList();
    final motionShapes = LegoConstants.brickShapes.where((s) => s.hasWheels).toList();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      left: 0,
      top: toolbarH,
      bottom: 0,
      width: collapsed ? collapsedW : leftW,
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            border: Border(right: BorderSide(color: Colors.grey.shade700, width: 1)),
          ),
          child: Offstage(
            offstage: collapsed,
            child: Column(
              children: [
                // Library header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
                  ),
                  child: const Text(
                    '积木库',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Drag hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.blue.shade300,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '长按拖拽到画布',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab bar - 紧凑风格
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.5),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('基础', 0),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildTabButton('运动', 1),
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 基础积木
                      _buildShapeGrid(basicShapes, legoNotifier),
                      // 运动积木
                      _buildShapeGrid(motionShapes, legoNotifier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabController.index == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.grey.shade800 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected 
                ? Colors.grey.shade700 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade500,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeGrid(List<BrickShape> shapes, legoNotifier) {
    if (shapes.isEmpty) {
      return Center(
        child: Text(
          '暂无积木',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: shapes.length,
        itemBuilder: (context, index) {
          final shape = shapes[index];
          return LongPressDraggable<BrickShape>(
            data: shape,
            feedback: const SizedBox.shrink(), // 不显示反馈，只依赖3D预览
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildShapeItem(shape),
            ),
            onDragStarted: () {
              legoNotifier.startDragging(shape);
            },
            onDragEnd: (details) {
              legoNotifier.endDragging();
            },
            child: GestureDetector(
              onTap: () {
                legoNotifier.setSelectedShape(shape);
                legoNotifier.setToolMode(ToolMode.build);
              },
              child: _buildShapeItem(shape),
            ),
          );
        },
      ),
    );
  }

  // 构建积木凸粒预览图
  Widget _buildBrickPreview(BrickShape shape, double maxWidth) {
    final width = shape.size[0]; // X方向
    final depth = shape.size[2]; // Z方向
    final maxDim = width > depth ? width : depth;
    
    // 计算每个凸粒的大小，限制最大值避免溢出
    final studSize = ((maxWidth * 0.65) / maxDim).clamp(4.0, 12.0);
    final spacing = studSize * 0.12;
    
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(depth, (z) {
              return Padding(
                padding: EdgeInsets.only(bottom: z < depth - 1 ? spacing : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(width, (x) {
                    return Container(
                      width: studSize,
                      height: studSize,
                      margin: EdgeInsets.only(right: x < width - 1 ? spacing : 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 0.5,
                            offset: const Offset(0, 0.5),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          // 如果有轮子，在四角显示小轮子图标
          if (shape.hasWheels)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(studSize * 0.3),
                child: Stack(
                  children: [
                    // 左上轮
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: studSize * 0.8,
                        height: studSize * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade600, width: 1),
                        ),
                      ),
                    ),
                    // 右上轮
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: studSize * 0.8,
                        height: studSize * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade600, width: 1),
                        ),
                      ),
                    ),
                    // 左下轮
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        width: studSize * 0.8,
                        height: studSize * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade600, width: 1),
                        ),
                      ),
                    ),
                    // 右下轮
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: studSize * 0.8,
                        height: studSize * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade600, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShapeItem(BrickShape shape) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.5),
          border: Border.all(
            color: Colors.grey.shade700,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 检查padding后的实际可用空间，至少需要30px才能正常显示
              if (constraints.maxWidth < 30 || constraints.maxHeight < 30) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Center(
                      child: _buildBrickPreview(shape, constraints.maxWidth * 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shape.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RightSidebar extends ConsumerWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legoState = ref.watch(legoProvider);
    final legoNotifier = ref.watch(legoNotifierProvider);

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final double toolbarH = screenH < 800 ? 48.0 : 52.0;
    final double rightW = screenW < 1100 ? 220.0 : 288.0;
    final bool rCollapsed = ref.watch(rightCollapsedProvider);
    const double collapsedW = 44.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      right: 0,
      top: toolbarH,
      bottom: 0,
      width: rCollapsed ? collapsedW : rightW,
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            border: Border(left: BorderSide(color: Colors.grey.shade700, width: 1)),
          ),
          child: Offstage(
            offstage: rCollapsed,
            child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMaterialsSection(legoState, legoNotifier),
              _buildTransformSection(legoState, legoNotifier),
              _buildSceneSettingsSection(legoState, legoNotifier),
              Container(
                padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(),
                child: const Text(
                  'BrickStudio v1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildMaterialsSection(LegoState legoState, LegoNotifier legoNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '材质',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: LegoConstants.brickColors.length,
            itemBuilder: (context, index) {
              final color = LegoConstants.brickColors[index];
              final isSelected = legoState.selectedColor == color.value;
              return GestureDetector(
                onTap: () => legoNotifier.setSelectedColor(color.value),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseColor(color.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // 空间太小时不显示颜色值
              if (constraints.maxWidth < 80) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  const Flexible(
                    flex: 0,
                    child: Text(
                      '颜色值:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        legoState.selectedColor.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // 高度切换开关
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 100) {
                return const SizedBox.shrink();
              }
              return _buildToggleRow(
                '使用薄积木',
                legoState.isPlateMode,
                () => legoNotifier.setIsPlateMode(!legoState.isPlateMode),
                Icons.layers_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransformSection(LegoState legoState, LegoNotifier legoNotifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      child: Column(
        children: [
          // 简洁标题
          const Text(
            '积木旋转',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // 简化的旋转控件
          Row(
            children: [
              // 角度显示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${legoState.rotation * 90}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 旋转按钮
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextButton.icon(
                    onPressed: legoNotifier.rotate,
                    icon: const Icon(Icons.rotate_right, size: 16),
                    label: const Text('旋转90°'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSceneSettingsSection(LegoState legoState, LegoNotifier legoNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('场景', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildToggleRow('显示网格', legoState.showGrid, () => legoNotifier.setShowGrid(!legoState.showGrid), Icons.grid_on),
          const SizedBox(height: 8),
          _buildToggleRow('阴影', legoState.showShadows, () => legoNotifier.setShowShadows(!legoState.showShadows), Icons.light_mode),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool active, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 空间太小时不显示内容
            if (constraints.maxWidth < 70) {
              return const SizedBox.shrink();
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label, 
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: active ? Colors.blue.shade500 : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? Colors.blue.shade400 : Colors.grey.shade600,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active 
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        blurRadius: active ? 4 : 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }
}

class _CompactToolButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color activeColor;
  const _CompactToolButton({required this.active, required this.onPressed, required this.icon, required this.label, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? activeColor.withOpacity(0.8) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? activeColor : Colors.transparent, width: 1),
            ),
            child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
                Icon(icon, size: 16, color: active ? Colors.white : Colors.grey.shade400),
          const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? Colors.white : Colors.grey.shade400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isActive;
  final String tooltip;
  const _HistoryButton({required this.onPressed, required this.icon, required this.isActive, required this.tooltip});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isActive ? Colors.grey.shade500 : Colors.grey.shade700, width: 1),
            ),
            child: Icon(icon, size: 16, color: isActive ? Colors.grey.shade200 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// Collapse handles (overlayed on edges)
class _LeftCollapseHandle extends ConsumerStatefulWidget {
  const _LeftCollapseHandle();
  @override
  ConsumerState<_LeftCollapseHandle> createState() => _LeftCollapseHandleState();
}

class _LeftCollapseHandleState extends ConsumerState<_LeftCollapseHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final double toolbarH = screenH < 800 ? 48.0 : 52.0;
    final double leftW = screenW < 1100 ? 200.0 : 256.0;
    const double collapsedW = 44.0;
    const double handleSize = 32.0; // 圆形按钮尺寸

    final collapsed = ref.watch(leftCollapsedProvider);
    final double x = (collapsed ? collapsedW : leftW) - handleSize / 2;
    final double y = toolbarH + 20; // 距离顶部固定距离

    return Positioned(
      left: x,
      top: y,
      width: handleSize,
      height: handleSize,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ref.read(leftCollapsedProvider.notifier).state = !collapsed,
            borderRadius: BorderRadius.circular(handleSize / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isHovered 
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered 
                      ? Colors.grey.shade500
                      : Colors.grey.shade700.withOpacity(0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                color: _isHovered ? Colors.white : Colors.white54,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RightCollapseHandle extends ConsumerStatefulWidget {
  const _RightCollapseHandle();
  @override
  ConsumerState<_RightCollapseHandle> createState() => _RightCollapseHandleState();
}

class _RightCollapseHandleState extends ConsumerState<_RightCollapseHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final double toolbarH = screenH < 800 ? 48.0 : 52.0;
    final double rightW = screenW < 1100 ? 220.0 : 288.0;
    const double collapsedW = 44.0;
    const double handleSize = 32.0; // 圆形按钮尺寸

    final collapsed = ref.watch(rightCollapsedProvider);
    final double xFromRight = (collapsed ? collapsedW : rightW) - handleSize / 2;
    final double y = toolbarH + 20; // 距离顶部固定距离

    return Positioned(
      right: xFromRight,
      top: y,
      width: handleSize,
      height: handleSize,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ref.read(rightCollapsedProvider.notifier).state = !collapsed,
            borderRadius: BorderRadius.circular(handleSize / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isHovered 
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered 
                      ? Colors.grey.shade500
                      : Colors.grey.shade700.withOpacity(0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                collapsed ? Icons.chevron_left : Icons.chevron_right,
                color: _isHovered ? Colors.white : Colors.white54,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
