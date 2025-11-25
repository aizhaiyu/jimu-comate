import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app/models/lego_models.dart';

/// 积木搭建状态数据模型
class LegoState {
  final List<BrickData> bricks;
  final String selectedColor;
  final BrickShape selectedShape;
  final ToolMode toolMode;
  final int rotation;
  final ViewMode viewMode;
  final bool showGrid;
  final bool showShadows;
  final bool isPlateMode; // true=矮积木(Plate), false=高积木(Brick)
  final List<List<BrickData>> history;
  final int historyIndex;
  final bool isDragging; // 是否正在拖拽
  final BrickShape? draggingShape; // 正在拖拽的积木形状

  const LegoState({
    this.bricks = const [],
    this.selectedColor = '#ef4444',
    this.selectedShape = _defaultShape, // 2x4 brick
    this.toolMode = ToolMode.build,
    this.rotation = 0,
    this.viewMode = ViewMode.editor,
    this.showGrid = true,
    this.showShadows = true,
    this.isPlateMode = false,
    this.history = const [],
    this.historyIndex = -1,
    this.isDragging = false,
    this.draggingShape,
  });

  static const BrickShape _defaultShape = BrickShape(id: '2x4', name: '2x4', size: [2, 1, 4]);

  LegoState copyWith({
    List<BrickData>? bricks,
    String? selectedColor,
    BrickShape? selectedShape,
    ToolMode? toolMode,
    int? rotation,
    ViewMode? viewMode,
    bool? showGrid,
    bool? showShadows,
    bool? isPlateMode,
    List<List<BrickData>>? history,
    int? historyIndex,
    bool? isDragging,
    BrickShape? draggingShape,
    bool clearDraggingShape = false,
  }) {
    return LegoState(
      bricks: bricks ?? this.bricks,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedShape: selectedShape ?? this.selectedShape,
      toolMode: toolMode ?? this.toolMode,
      rotation: rotation ?? this.rotation,
      viewMode: viewMode ?? this.viewMode,
      showGrid: showGrid ?? this.showGrid,
      showShadows: showShadows ?? this.showShadows,
      isPlateMode: isPlateMode ?? this.isPlateMode,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      isDragging: isDragging ?? this.isDragging,
      draggingShape: clearDraggingShape ? null : (draggingShape ?? this.draggingShape),
    );
  }
}

/// 积木搭建状态管理器
class LegoNotifier extends StateNotifier<LegoState> {
  LegoNotifier() : super(const LegoState());

  final _uuid = const Uuid();

  void addToHistory(List<BrickData> newBricks) {
    final newHistory = state.history.length > state.historyIndex + 1
        ? state.history.sublist(0, state.historyIndex + 1)
        : List<List<BrickData>>.from(state.history);
    
    newHistory.add(List<BrickData>.from(newBricks));
    
    state = state.copyWith(
      bricks: newBricks,
      history: newHistory,
      historyIndex: newHistory.length - 1,
    );
  }

  void addBrick(List<double> position) {
    // 根据isPlateMode调整高度：Plate是Brick高度的1/3
    final adjustedSize = state.isPlateMode 
        ? [state.selectedShape.size[0], 0.33, state.selectedShape.size[2]]
        : state.selectedShape.size;
    
    final newBrick = BrickData(
      id: _uuid.v4(),
      position: position,
      color: state.selectedColor,
      size: adjustedSize,
      rotation: state.rotation,
      hasWheels: state.selectedShape.hasWheels,
    );
    
    final newBricks = [...state.bricks, newBrick];
    addToHistory(newBricks);
  }

  // 直接添加完整的积木数据（用于恢复项目）
  void addBrickDirect(BrickData brick) {
    final newBricks = [...state.bricks, brick];
    addToHistory(newBricks);
  }

  void removeBrick(String id) {
    final newBricks = state.bricks.where((brick) => brick.id != id).toList();
    addToHistory(newBricks);
  }

  void paintBrick(String id) {
    final newBricks = state.bricks.map((brick) {
      return brick.id == id 
          ? brick.copyWith(color: state.selectedColor)
          : brick;
    }).toList();
    
    addToHistory(newBricks);
  }

  void moveBrick(String id, List<double> newPosition) {
    final newBricks = state.bricks.map((brick) {
      return brick.id == id 
          ? brick.copyWith(position: newPosition)
          : brick;
    }).toList();
    
    addToHistory(newBricks);
  }

  void setSelectedColor(String color) {
    state = state.copyWith(selectedColor: color);
  }

  void setSelectedShape(BrickShape shape) {
    state = state.copyWith(selectedShape: shape);
  }

  void setToolMode(ToolMode mode) {
    state = state.copyWith(toolMode: mode);
  }

  void rotate() {
    state = state.copyWith(rotation: (state.rotation + 1) % 4);
  }

  void undo() {
    if (state.historyIndex > 0) {
      state = state.copyWith(
        bricks: state.history[state.historyIndex - 1],
        historyIndex: state.historyIndex - 1,
      );
    } else if (state.historyIndex == 0) {
      state = state.copyWith(
        bricks: [],
        historyIndex: -1,
      );
    }
  }

  void redo() {
    if (state.historyIndex < state.history.length - 1) {
      state = state.copyWith(
        bricks: state.history[state.historyIndex + 1],
        historyIndex: state.historyIndex + 1,
      );
    }
  }

  void clear() {
    addToHistory([]);
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setShowGrid(bool show) {
    state = state.copyWith(showGrid: show);
  }

  void setShowShadows(bool show) {
    state = state.copyWith(showShadows: show);
  }

  void setIsPlateMode(bool isPlate) {
    state = state.copyWith(isPlateMode: isPlate);
  }

  void startDragging(BrickShape shape) {
    state = state.copyWith(
      isDragging: true,
      draggingShape: shape,
      selectedShape: shape,
      toolMode: ToolMode.build,
    );
  }

  void endDragging() {
    state = state.copyWith(
      isDragging: false,
      clearDraggingShape: true,
    );
  }

  bool get canUndo => state.historyIndex >= 0;
  bool get canRedo => state.historyIndex < state.history.length - 1;
}

// Providers
final legoProvider = StateNotifierProvider<LegoNotifier, LegoState>((ref) {
  return LegoNotifier();
});

final legoNotifierProvider = Provider<LegoNotifier>((ref) {
  return ref.watch(legoProvider.notifier);
});