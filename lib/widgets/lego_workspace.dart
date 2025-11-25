import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/models/lego_models.dart';

class LegoWorkspace extends StatefulWidget {
  final List<BrickData> bricks;
  final ToolMode toolMode;
  final BrickShape selectedShape;
  final String selectedColor;
  final int rotation;
  final ViewMode viewMode;
  final bool showGrid;
  final bool showShadows;
  final bool isPlateMode;
  final Function(BrickData) onAddBrick;
  final Function(String) onRemoveBrick;
  final Function(String) onPaintBrick;
  final Function(String brickId, List<double> position) onMoveBrick;

  const LegoWorkspace({
    super.key,
    required this.bricks,
    required this.toolMode,
    required this.selectedShape,
    required this.selectedColor,
    required this.rotation,
    required this.viewMode,
    required this.showGrid,
    required this.showShadows,
    required this.isPlateMode,
    required this.onAddBrick,
    required this.onRemoveBrick,
    required this.onPaintBrick,
    required this.onMoveBrick,
  });

  @override
  LegoWorkspaceState createState() => LegoWorkspaceState();
}

class LegoWorkspaceState extends State<LegoWorkspace> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  Offset? _dragPosition;
  String _threeJSContent = '';

  @override
  void initState() {
    super.initState();
    _loadThreeJS();
  }

  Future<void> _loadThreeJS() async {
    try {
      final content = await rootBundle.loadString('assets/three/three.min.js');
      setState(() {
        _threeJSContent = content;
      });
    } catch (e) {
      debugPrint('加载 three.js 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 等待 three.js 加载完成
    if (_threeJSContent.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    return DragTarget<BrickShape>(
      onWillAcceptWithDetails: (details) {
        return true; // 接受所有BrickShape类型的拖拽
      },
      onAcceptWithDetails: (details) {
        // 当拖拽松手时，在3D场景中放置积木
        _handleDrop(details.offset);
        setState(() {
          _dragPosition = null;
        });
      },
      onMove: (details) {
        // 拖拽移动时更新位置和3D预览
        setState(() {
          _dragPosition = details.offset;
        });
        _updateDragPreview(details.offset);
      },
      onLeave: (data) {
        setState(() {
          _dragPosition = null;
        });
        _clearDragPreview();
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            InAppWebView(
          initialData: InAppWebViewInitialData(
            data: _getThreeJSHTML(),
            baseUrl: WebUri('https://localhost/'),
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onLoadStop: (controller, url) async {
            setState(() {
              _isLoading = false;
            });
            _initializeScene();
          },
          onConsoleMessage: (controller, consoleMessage) {
            if (kDebugMode) {
              debugPrint('WebView Console: ${consoleMessage.message}');
            }
          },
          initialSettings: InAppWebViewSettings(
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            supportZoom: false,
            javaScriptEnabled: true,
            allowsAirPlayForMediaPlayback: true,
            allowsPictureInPictureMediaPlayback: true,
          ),
        ),
        // Flutter层的全屏加载遮罩，完全遮住白屏
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF111827),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.blue,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '3D场景加载中...',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // 拖拽时显示简单的十字准星提示
        if (_dragPosition != null && candidateData.isNotEmpty)
              Positioned(
                left: _dragPosition!.dx - 20,
                top: _dragPosition!.dy - 20,
                child: IgnorePointer(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _updateDragPreview(Offset position) {
    if (_webViewController == null || _isLoading) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localPosition = renderBox.globalToLocal(position);
    
    final normalizedX = (localPosition.dx / size.width) * 2 - 1;
    final normalizedY = -(localPosition.dy / size.height) * 2 + 1;

    // 在3D场景中显示半透明预览
    _webViewController!.evaluateJavascript(source: '''
      (function() {
        try {
          if (!raycaster || !camera || !floorPlane) return;
          
          const mouse = new THREE.Vector2($normalizedX, $normalizedY);
          raycaster.setFromCamera(mouse, camera);
          
          const intersects = raycaster.intersectObjects(scene.children, true).filter((i) => {
            let o = i.object;
            while (o) {
              if (o.name === 'hoverBrick' || o.name === 'dragPreview') return false;
              o = o.parent;
            }
            return true;
          });
          
          // 清除旧的拖拽预览
          const oldPreview = scene.getObjectByName('dragPreview');
          if (oldPreview) scene.remove(oldPreview);
          
          if (intersects.length > 0) {
            const hit = intersects[0];
            const isFloor = hit.object === floorPlane;
            let normal = new THREE.Vector3(0, 1, 0);
            if (!isFloor && hit.face) {
              normal = hit.face.normal.clone();
              normal.transformDirection(hit.object.matrixWorld);
            }
            
            let refMeta = null;
            let refBrick = null;
            if (!isFloor) {
              let refObj = hit.object;
              while (refObj && !refObj.userData.brickId) refObj = refObj.parent;
              if (refObj && refObj.userData && refObj.userData.size) {
                refMeta = { size: refObj.userData.size, rotation: refObj.userData.rotation || 0 };
                const brickId = refObj.userData.brickId;
                refBrick = bricks.find(b => b.id === brickId);
              }
            }
            
            const baseSnap = snapToGrid(hit.point, normal, isFloor, refMeta, refBrick);
            let candidate = baseSnap;
            let noOverlap = !willOverlap(candidate, selectedShape.size, rotation);
            let supported = hasSupport(candidate, selectedShape.size, rotation);
            let valid = noOverlap && supported;
            
            // 总是检查碰撞区域最高点，如果有碰撞就向上堆叠
            const highestTop = findHighestCollisionTop(candidate, selectedShape.size, rotation);
            
            if (highestTop > 0 && !noOverlap) {
              // 有碰撞，将积木放置在最高碰撞点之上
              const h = selectedShape.size[1];
              const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
              
              // 将积木放置在最高碰撞点之上，确保底部紧贴顶部
              let newY = highestTop + actualHeight / 2;
              
              // 对齐到 PLATE_HEIGHT 网格，但确保至少在最高点上方
              const yLevel = Math.round((newY - actualHeight / 2) / PLATE_HEIGHT);
              newY = yLevel * PLATE_HEIGHT + actualHeight / 2;
              
              // 确保新位置不低于最高点
              if (newY - actualHeight / 2 < highestTop) {
                newY = highestTop + actualHeight / 2;
              }
              
              const upwardCandidate = [candidate[0], newY, candidate[2]];
              
              const tryNoOverlap = !willOverlap(upwardCandidate, selectedShape.size, rotation);
              
              // 对于向上堆叠，只需要检查无重叠
              if (tryNoOverlap) {
                candidate = upwardCandidate;
                valid = true;
              }
            }
            
            // 如果还是无效，尝试水平偏移
            if (!valid) {
              const horizontalOffsets = [
                [0.5, 0, 0], [-0.5, 0, 0], [0, 0, 0.5], [0, 0, -0.5],
                [0.5, 0, 0.5], [-0.5, 0, 0.5], [0.5, 0, -0.5], [-0.5, 0, -0.5]
              ];
              
              for (const off of horizontalOffsets) {
                const tryPos = [candidate[0] + off[0], candidate[1] + off[1], candidate[2] + off[2]];
                const tryNoOverlap = !willOverlap(tryPos, selectedShape.size, rotation);
                const trySupported = hasSupport(tryPos, selectedShape.size, rotation);
                if (tryNoOverlap && trySupported) {
                  candidate = tryPos;
                  valid = true;
                  break;
                }
              }
            }
            
            const previewColor = valid ? selectedColor : '#EF4444';
            
            // 创建半透明预览积木（使用调整后的位置）
            const preview = createLegoPiece(candidate, selectedShape.size, previewColor, rotation, true, 0.6, selectedShape.hasWheels || false);
            preview.name = 'dragPreview';
            scene.add(preview);
          }
        } catch(e) {
          console.error('Drag preview error:', e);
        }
      })();
    ''');
  }

  void _clearDragPreview() {
    if (_webViewController == null) return;
    
    _webViewController!.evaluateJavascript(source: '''
      (function() {
        const preview = scene.getObjectByName('dragPreview');
        if (preview) scene.remove(preview);
      })();
    ''');
  }

  void _handleDrop(Offset position) {
    if (_webViewController == null) return;

    // 清除拖拽预览
    _clearDragPreview();

    // 将屏幕坐标转换为WebView坐标（归一化到-1到1）
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localPosition = renderBox.globalToLocal(position);
    
    // 转换为Three.js的标准化坐标
    final normalizedX = (localPosition.dx / size.width) * 2 - 1;
    final normalizedY = -(localPosition.dy / size.height) * 2 + 1;

    // 使用新的JavaScript函数放置积木
    _webViewController!.evaluateJavascript(source: '''
      (function() {
        if (window.placeBrickAtScreenPosition) {
          const success = window.placeBrickAtScreenPosition($normalizedX, $normalizedY);
          if (!success) {
            console.warn('Failed to place brick at drop position');
          }
        }
      })();
    ''');
  }

  String _getThreeJSHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LEGO 3D Studio</title>
    <style>
        body { margin: 0; padding: 0; overflow: hidden; background-color: #111827; }
        canvas { display: block; }
        #loading-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: #111827;
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 9999;
            color: #9ca3af;
            font-family: Arial, sans-serif;
            font-size: 14px;
        }
        .spinner {
            width: 40px;
            height: 40px;
            border: 3px solid #374151;
            border-top: 3px solid #3b82f6;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="loading-overlay">
        <div style="text-align: center;">
            <div class="spinner" style="margin: 0 auto;"></div>
            <div style="margin-top: 16px;">初始化3D场景...</div>
        </div>
    </div>
    <script>
        // Three.js v0.160.0 - 本地版本
        $_threeJSContent
    </script>
    <script>
        let scene, camera, renderer, controls;
        let bricks = [];
        let raycaster, mouse;
        let floorPlane;
        let toolMode = 'build';
        let selectedShape = { size: [2, 1, 4], hasWheels: false };
        let selectedColor = '#ef4444';
        let rotation = 0;
        let viewMode = 'editor';
        let showGrid = true;
        let showShadows = true;
        let hoverPosition = null;
        let lastTouch = null;
        // 移除pendingPos和pendingValid，不再需要两次点击确认

        const BRICK_UNIT = 1.0;
        const BRICK_HEIGHT = 1.2;  // 标准积木高度
        const PLATE_HEIGHT = 0.4;  // 矮积木高度（1/3）
        const PLATE_RATIO = 0.33;  // 矮积木高度比例

        // Occupancy grid - 使用更精确的高度单位（0.4为基本单位，3个Plate=1个Brick）
        const occupancy = new Set();
        const occKey = (x2, yLevel, z2) => (x2 + '|' + yLevel + '|' + z2);
        
        // 将实际高度转换为层级（以0.4为单位）
        function getHeightLevels(h) {
            if (h <= PLATE_RATIO + 0.01) return 1; // Plate占1层
            return 3; // Brick占3层
        }
        
        function occupyForBrick(pos, size, rot) {
            const w = (rot % 2 === 0) ? size[0] : size[2];
            const d = (rot % 2 === 0) ? size[2] : size[0];
            const h = size[1];
            const heightLevels = getHeightLevels(h);
            const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
            
            // 计算底部层级（以0.4为单位）
            const baseLevel = Math.round((pos[1] - actualHeight / 2) / PLATE_HEIGHT);
            const startX = pos[0] - ((w - 1) * BRICK_UNIT) / 2;
            const startZ = pos[2] - ((d - 1) * BRICK_UNIT) / 2;
            
            for (let yi = 0; yi < heightLevels; yi++) {
                const yL = baseLevel + yi;
                for (let i = 0; i < w; i++) {
                    for (let j = 0; j < d; j++) {
                        const x2 = Math.round((startX + i * BRICK_UNIT) * 2);
                        const z2 = Math.round((startZ + j * BRICK_UNIT) * 2);
                        occupancy.add(occKey(x2, yL, z2));
                    }
                }
            }
        }
        
        function rebuildOccupancy(bricksData) {
            occupancy.clear();
            bricksData.forEach(b => occupyForBrick(b.position, b.size, b.rotation));
        }
        
        function willOverlap(pos, size, rot) {
            const w = (rot % 2 === 0) ? size[0] : size[2];
            const d = (rot % 2 === 0) ? size[2] : size[0];
            const h = size[1];
            const heightLevels = getHeightLevels(h);
            const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
            
            const baseLevel = Math.round((pos[1] - actualHeight / 2) / PLATE_HEIGHT);
            const startX = pos[0] - ((w - 1) * BRICK_UNIT) / 2;
            const startZ = pos[2] - ((d - 1) * BRICK_UNIT) / 2;
            
            for (let yi = 0; yi < heightLevels; yi++) {
                const yL = baseLevel + yi;
                for (let i = 0; i < w; i++) {
                    for (let j = 0; j < d; j++) {
                        const x2 = Math.round((startX + i * BRICK_UNIT) * 2);
                        const z2 = Math.round((startZ + j * BRICK_UNIT) * 2);
                        if (occupancy.has(occKey(x2, yL, z2))) return true;
                    }
                }
            }
            return false;
        }

        // 检查积木下方是否有支撑（地面或其他积木）
        function hasSupport(pos, size, rot) {
            const h = size[1];
            const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
            const bottomY = pos[1] - actualHeight / 2;
            
            // 如果底部在地面上或接近地面（误差范围0.15），认为有支撑
            if (bottomY <= 0.15) return true;
            
            // 检查下方是否有积木支撑
            // 需要至少50%的面积有支撑
            const w = (rot % 2 === 0) ? size[0] : size[2];
            const d = (rot % 2 === 0) ? size[2] : size[0];
            const startX = pos[0] - ((w - 1) * BRICK_UNIT) / 2;
            const startZ = pos[2] - ((d - 1) * BRICK_UNIT) / 2;
            
            // 计算下方需要检查的level（紧贴积木底部下方）
            const belowLevel = Math.round(bottomY / PLATE_HEIGHT) - 1;
            
            // 如果计算出的level小于0，说明在地面下，应该有支撑
            if (belowLevel < 0) return true;
            
            let supportCount = 0;
            let totalCount = 0;
            
            for (let i = 0; i < w; i++) {
                for (let j = 0; j < d; j++) {
                    totalCount++;
                    const x2 = Math.round((startX + i * BRICK_UNIT) * 2);
                    const z2 = Math.round((startZ + j * BRICK_UNIT) * 2);
                    // 检查下方是否有积木占据
                    if (occupancy.has(occKey(x2, belowLevel, z2))) {
                        supportCount++;
                    }
                }
            }
            
            // 至少需要50%的面积有支撑
            return supportCount >= totalCount * 0.5;
        }

        // 找到在给定XZ位置碰撞的最高积木顶部Y坐标
        function findHighestCollisionTop(pos, size, rot) {
            const w = (rot % 2 === 0) ? size[0] : size[2];
            const d = (rot % 2 === 0) ? size[2] : size[0];
            const h = size[1];
            const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
            
            // 正确计算边界：实际宽度 = w * BRICK_UNIT
            const startX = pos[0] - (w * BRICK_UNIT) / 2;
            const startZ = pos[2] - (d * BRICK_UNIT) / 2;
            const endX = pos[0] + (w * BRICK_UNIT) / 2;
            const endZ = pos[2] + (d * BRICK_UNIT) / 2;
            
            let maxTopY = 0;
            
            // 遍历所有现有积木，找到在XZ平面上重叠且顶部最高的积木
            for (const brick of bricks) {
                const bw = (brick.rotation % 2 === 0) ? brick.size[0] : brick.size[2];
                const bd = (brick.rotation % 2 === 0) ? brick.size[2] : brick.size[0];
                const bh = brick.size[1];
                const bActualHeight = (bh <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
                
                // 正确计算现有积木的边界
                const bStartX = brick.position[0] - (bw * BRICK_UNIT) / 2;
                const bStartZ = brick.position[2] - (bd * BRICK_UNIT) / 2;
                const bEndX = brick.position[0] + (bw * BRICK_UNIT) / 2;
                const bEndZ = brick.position[2] + (bd * BRICK_UNIT) / 2;
                
                // 检查XZ平面是否重叠
                const overlapX = !(endX <= bStartX || startX >= bEndX);
                const overlapZ = !(endZ <= bStartZ || startZ >= bEndZ);
                
                if (overlapX && overlapZ) {
                    const bTopY = brick.position[1] + bActualHeight / 2;
                    maxTopY = Math.max(maxTopY, bTopY);
                }
            }
            
            return maxTopY;
        }

        class SimpleOrbitControls {
            constructor(camera, domElement) {
                this.camera = camera;
                this.domElement = domElement;
                this.target = new THREE.Vector3(0, 0, 0);
                this.enableDamping = true;
                this.dampingFactor = 0.05;
                this.minDistance = 5;
                this.maxDistance = 100;
                this.enabled = true; // 控制是否启用OrbitControls
                
                // 限制垂直旋转角度，避免万向锁
                this.minPolarAngle = 0.1; // 防止到达正上方
                this.maxPolarAngle = Math.PI - 0.1; // 防止到达正下方

                // expose drag state
                this.isDragging = false;
                this.wasDragging = false;
                
                let spherical = new THREE.Spherical();
                let sphericalDelta = new THREE.Spherical();
                let scale = 1;
                let isMouseDown = false;
                let previousMousePosition = { x: 0, y: 0 };
                let moved = false;
                // panning helper used in View mode
                const pan = (deltaX, deltaY) => {
                    const element = this.domElement;
                    const offset = new THREE.Vector3();
                    offset.copy(this.camera.position).sub(this.target);
                    const targetDistance = Math.max(0.001, offset.length());
                    // normalize by element height to keep speed consistent
                    const dx = - deltaX * (targetDistance / Math.max(1, element.clientHeight)) * 1.2;
                    const dy =   deltaY * (targetDistance / Math.max(1, element.clientHeight)) * 1.2;
                    // camera axes from matrix columns
                    this.camera.updateMatrix();
                    const xAxis = new THREE.Vector3().setFromMatrixColumn(this.camera.matrix, 0).multiplyScalar(dx);
                    const yAxis = new THREE.Vector3().setFromMatrixColumn(this.camera.matrix, 1).multiplyScalar(dy);
                    const panOffset = new THREE.Vector3().copy(xAxis).add(yAxis);
                    this.camera.position.add(panOffset);
                    this.target.add(panOffset);
                };
                
                this.update = () => {
                    const offset = new THREE.Vector3();
                    const quat = new THREE.Quaternion().setFromUnitVectors(
                        this.camera.up, new THREE.Vector3(0, 1, 0)
                    );
                    const quatInverse = quat.clone().invert();
                    
                    offset.copy(this.camera.position).sub(this.target);
                    offset.applyQuaternion(quat);
                    
                    spherical.setFromVector3(offset);
                    
                    if (this.enableDamping) {
                        spherical.theta += sphericalDelta.theta * this.dampingFactor;
                        spherical.phi += sphericalDelta.phi * this.dampingFactor;
                        sphericalDelta.theta *= (1 - this.dampingFactor);
                        sphericalDelta.phi *= (1 - this.dampingFactor);
                    }
                    
                    // 限制垂直角度，防止万向锁和抖动
                    spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, spherical.phi));
                    
                    spherical.radius *= scale;
                    spherical.radius = Math.max(this.minDistance, Math.min(this.maxDistance, spherical.radius));
                    
                    offset.setFromSpherical(spherical);
                    offset.applyQuaternion(quatInverse);
                    
                    this.camera.position.copy(this.target).add(offset);
                    this.camera.lookAt(this.target);
                    // reset zoom scale after applying each frame
                    scale = 1;
                    return true;
                };
                
                const handleMouseDownRotate = (event) => {
                    if (!this.enabled) return;
                    isMouseDown = true;
                    moved = false;
                    this.isDragging = true;
                    previousMousePosition = { x: event.clientX, y: event.clientY };
                    sphericalDelta.set(0, 0, 0);
                    event.preventDefault();
                };
                
                const handleMouseMoveRotate = (event) => {
                    if (!this.enabled || !isMouseDown) return;
                    moved = true;
                    const deltaX = event.clientX - previousMousePosition.x;
                    const deltaY = event.clientY - previousMousePosition.y;
                    
                    if (toolMode === 'view') {
                        pan(deltaX, deltaY);
                    } else {
                        sphericalDelta.theta -= deltaX * 0.01;
                        sphericalDelta.phi -= deltaY * 0.01;
                    }
                    
                    previousMousePosition = { x: event.clientX, y: event.clientY };
                };
                
                const handleMouseUp = () => {
                    isMouseDown = false;
                    this.isDragging = false;
                    this.wasDragging = moved;
                    // reset after click event bubble
                    setTimeout(() => { this.wasDragging = false; }, 50);
                };
                
                const handleWheel = (event) => {
                    if (!this.enabled) return;
                    event.preventDefault();
                    if (event.deltaY < 0) {
                        scale *= 0.95;
                    } else {
                        scale *= 1.05;
                    }
                };
                
                this.domElement.addEventListener('mousedown', handleMouseDownRotate);
                this.domElement.addEventListener('mousemove', handleMouseMoveRotate);
                this.domElement.addEventListener('mouseup', handleMouseUp);
                this.domElement.addEventListener('wheel', handleWheel, { passive: false });

                // Touch support
                const handleTouchStart = (event) => {
                    if (!this.enabled) return;
                    if (event.touches.length >= 1) {
                        isMouseDown = true;
                        moved = false;
                        this.isDragging = true;
                        previousMousePosition = { x: event.touches[0].clientX, y: event.touches[0].clientY };
                        sphericalDelta.set(0, 0, 0);
                    }
                    // Prevent default to avoid page scroll/zoom
                    event.preventDefault();
                };

                const handleTouchMove = (event) => {
                    if (!this.enabled) return;
                    if (event.touches.length === 1 && isMouseDown) {
                        moved = true;
                        const deltaX = event.touches[0].clientX - previousMousePosition.x;
                        const deltaY = event.touches[0].clientY - previousMousePosition.y;

                        if (toolMode === 'view') {
                            pan(deltaX, deltaY);
                        } else {
                            sphericalDelta.theta -= deltaX * 0.01;
                            sphericalDelta.phi -= deltaY * 0.01;
                        }

                        previousMousePosition = { x: event.touches[0].clientX, y: event.touches[0].clientY };
                    } else if (event.touches.length === 2) {
                        // Pinch zoom
                        moved = true;
                        const dx = event.touches[0].clientX - event.touches[1].clientX;
                        const dy = event.touches[0].clientY - event.touches[1].clientY;
                        const distance = Math.sqrt(dx * dx + dy * dy);
                        if (this.__lastPinchDistance !== undefined) {
                            const delta = distance - this.__lastPinchDistance;
                            if (delta > 0) {
                                // spread fingers → zoom in (radius smaller)
                                scale *= 0.98;
                            } else {
                                // pinch in → zoom out (radius larger)
                                scale *= 1.02;
                            }
                        }
                        this.__lastPinchDistance = distance;
                    }
                    event.preventDefault();
                };

                const handleTouchEnd = (event) => {
                    isMouseDown = false;
                    this.isDragging = false;
                    this.wasDragging = moved;
                    this.__lastPinchDistance = undefined;
                    // reset after tap
                    setTimeout(() => { this.wasDragging = false; }, 80);
                    event.preventDefault();
                };

                this.domElement.addEventListener('touchstart', handleTouchStart, { passive: false });
                this.domElement.addEventListener('touchmove', handleTouchMove, { passive: false });
                this.domElement.addEventListener('touchend', handleTouchEnd, { passive: false });
            }
        }

        function init() {
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0x111827);

            camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.set(12, 12, 12);

            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.shadowMap.enabled = true;
            renderer.shadowMap.type = THREE.PCFSoftShadowMap;
            document.body.appendChild(renderer.domElement);

            controls = new SimpleOrbitControls(camera, renderer.domElement);

            // Lighting
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
            scene.add(ambientLight);

            if (showShadows) {
                const directionalLight = new THREE.DirectionalLight(0xffffff, 2);
                directionalLight.position.set(20, 30, 20);
                directionalLight.castShadow = true;
                directionalLight.shadow.mapSize.width = 2048;
                directionalLight.shadow.mapSize.height = 2048;
                directionalLight.shadow.camera.left = -30;
                directionalLight.shadow.camera.right = 30;
                directionalLight.shadow.camera.top = 30;
                directionalLight.shadow.camera.bottom = -30;
                directionalLight.shadow.camera.near = 0.1;
                directionalLight.shadow.camera.far = 100;
                scene.add(directionalLight);
            }

            // Grid
            const gridHelper = new THREE.GridHelper(60, 60, 0x6b7280, 0x374151);
            gridHelper.position.y = 0.005;
            gridHelper.name = 'GridHelper'; // 添加name以便后续查找和移除
            gridHelper.visible = showGrid; // 使用visible属性控制显示
            scene.add(gridHelper);

            // Floor plane for raycasting
            const floorGeometry = new THREE.PlaneGeometry(200, 200);
            const floorMaterial = new THREE.MeshBasicMaterial({ visible: false });
            floorPlane = new THREE.Mesh(floorGeometry, floorMaterial);
            floorPlane.rotation.x = -Math.PI / 2;
            floorPlane.name = 'floor';
            scene.add(floorPlane);

            raycaster = new THREE.Raycaster();
            mouse = new THREE.Vector2();

            window.addEventListener('resize', onWindowResize, false);

            animate();
        }

        function createLegoPiece(position, size, color, rotation, transparent = false, opacity = 1, hasWheels = false) {
            const group = new THREE.Group();
            group.position.set(...position);
            group.rotation.y = (rotation * Math.PI) / 2;
            // metadata for interactions
            group.userData.size = size;
            group.userData.rotation = rotation;
            group.userData.hasWheels = hasWheels;

            const width = size[0];
            const height = size[1];
            const depth = size[2];
            const actualWidth = width * BRICK_UNIT;
            // 根据height判断是Plate还是Brick
            const isPlate = (height <= PLATE_RATIO + 0.01);
            const actualHeight = isPlate ? PLATE_HEIGHT : BRICK_HEIGHT;
            const actualDepth = depth * BRICK_UNIT;

            // Main block
            const blockGeometry = new THREE.BoxGeometry(actualWidth - 0.02, actualHeight, actualDepth - 0.02);
            const blockMaterial = new THREE.MeshStandardMaterial({
                color: color,
                roughness: 0.3,
                metalness: 0.05,
                transparent: transparent,
                opacity: opacity,
            });
            const block = new THREE.Mesh(blockGeometry, blockMaterial);
            block.castShadow = true;
            block.receiveShadow = true;
            group.add(block);

            // Studs
            const studGeometry = new THREE.CylinderGeometry(0.3, 0.3, 0.2, 16);
            const studMaterial = new THREE.MeshStandardMaterial({ 
                color: color,
                transparent: transparent,
                opacity: transparent ? opacity : 1,
            });

            const startX = -((width - 1) * BRICK_UNIT) / 2;
            const startZ = -((depth - 1) * BRICK_UNIT) / 2;

            for (let i = 0; i < width; i++) {
                for (let j = 0; j < depth; j++) {
                    const stud = new THREE.Mesh(studGeometry, studMaterial);
                    stud.position.set(
                        startX + i * BRICK_UNIT,
                        actualHeight / 2 + 0.1,
                        startZ + j * BRICK_UNIT
                    );
                    stud.castShadow = true;
                    stud.receiveShadow = true;
                    group.add(stud);
                }
            }

            // 添加轮子（如果有）
            if (hasWheels) {
                const wheelRadius = 0.5;
                const wheelWidth = 0.3;
                const wheelGeometry = new THREE.CylinderGeometry(wheelRadius, wheelRadius, wheelWidth, 16);
                const wheelMaterial = new THREE.MeshStandardMaterial({
                    color: '#1f2937', // 深灰色/黑色轮子
                    roughness: 0.7,
                    metalness: 0.1,
                    transparent: transparent,
                    opacity: opacity,
                });

                // 车轮位置：在积木四角底部外侧
                const wheelOffsetX = actualWidth / 2 + 0.15;
                const wheelOffsetZ = actualDepth / 2 - 0.3;
                const wheelY = -actualHeight / 2 - wheelRadius + 0.1;

                // 前左轮
                const wheelFL = new THREE.Mesh(wheelGeometry, wheelMaterial);
                wheelFL.rotation.z = Math.PI / 2;
                wheelFL.position.set(-wheelOffsetX, wheelY, -wheelOffsetZ);
                wheelFL.castShadow = true;
                group.add(wheelFL);

                // 前右轮
                const wheelFR = new THREE.Mesh(wheelGeometry, wheelMaterial);
                wheelFR.rotation.z = Math.PI / 2;
                wheelFR.position.set(wheelOffsetX, wheelY, -wheelOffsetZ);
                wheelFR.castShadow = true;
                group.add(wheelFR);

                // 后左轮
                const wheelRL = new THREE.Mesh(wheelGeometry, wheelMaterial);
                wheelRL.rotation.z = Math.PI / 2;
                wheelRL.position.set(-wheelOffsetX, wheelY, wheelOffsetZ);
                wheelRL.castShadow = true;
                group.add(wheelRL);

                // 后右轮
                const wheelRR = new THREE.Mesh(wheelGeometry, wheelMaterial);
                wheelRR.rotation.z = Math.PI / 2;
                wheelRR.position.set(wheelOffsetX, wheelY, wheelOffsetZ);
                wheelRR.castShadow = true;
                group.add(wheelRR);
            }

            return group;
        }

        function updateBricks(bricksData) {
            // Clear hover brick first
            clearHoverBrick();

            // Remove old bricks
            const bricksToRemove = [];
            scene.traverse((child) => {
                if (child.userData.isBrick) {
                    bricksToRemove.push(child);
                }
            });
            bricksToRemove.forEach(brick => scene.remove(brick));

            // Add new bricks
            bricksData.forEach(brickData => {
                const brick = createLegoPiece(
                    brickData.position,
                    brickData.size,
                    brickData.color,
                    brickData.rotation,
                    false,
                    1,
                    brickData.hasWheels || false
                );
                brick.userData.isBrick = true;
                brick.userData.brickId = brickData.id;
                scene.add(brick);
            });

            // Re-add grid if needed
            if (showGrid && !scene.getObjectByName('GridHelper')) {
                const gridHelper = new THREE.GridHelper(60, 60, 0x6b7280, 0x374151);
                gridHelper.position.y = 0.005;
                scene.add(gridHelper);
            }

            // Rebuild occupancy map
            rebuildOccupancy(bricksData);
        }

        function clearHoverBrick() {
            // 清除所有预览积木（包括旧的hoverBrick和新的dragPreview）
            const hoverBrick = scene.getObjectByName('hoverBrick');
            if (hoverBrick) {
                scene.remove(hoverBrick);
            }
            const dragPreview = scene.getObjectByName('dragPreview');
            if (dragPreview) {
                scene.remove(dragPreview);
            }
            hoverPosition = null;
        }

        function snapToGrid(point, normal, isFloor, ref, refBrick) {
            const w = (rotation % 2 === 0) ? selectedShape.size[0] : selectedShape.size[2];
            const d = (rotation % 2 === 0) ? selectedShape.size[2] : selectedShape.size[0];
            const h = selectedShape.size[1];
            const isPlate = (h <= PLATE_RATIO + 0.01);
            const actualHeight = isPlate ? PLATE_HEIGHT : BRICK_HEIGHT;
            
            let x = point.x;
            let z = point.z;
            let y = point.y;

            if (isFloor) {
                // 在地面上放置，Y坐标为积木高度的一半
                y = actualHeight / 2;
                x = Math.round(x);
                z = Math.round(z);
            } else if (normal && Math.abs(normal.y) > 0.5) {
                // 在其他积木顶部堆叠（法线主要朝上）
                x = point.x;
                z = point.z;
                
                // 计算参考积木的顶部Y坐标
                if (refBrick && refBrick.position) {
                    const refH = refBrick.size[1];
                    const refIsPlate = (refH <= PLATE_RATIO + 0.01);
                    const refActualHeight = refIsPlate ? PLATE_HEIGHT : BRICK_HEIGHT;
                    const refTopY = refBrick.position[1] + refActualHeight / 2;
                    
                    // 新积木底部紧贴参考积木顶部
                    y = refTopY + actualHeight / 2;
                } else {
                    // 没有参考积木信息时使用对齐方式
                    const yLevel = Math.round(point.y / PLATE_HEIGHT);
                    y = yLevel * PLATE_HEIGHT + actualHeight / 2;
                }
            } else if (normal) {
                // 在侧面放置
                const offsetPoint = point.clone().add(normal.clone().multiplyScalar(0.5));
                x = offsetPoint.x;
                z = offsetPoint.z;
                const yLevel = Math.round(offsetPoint.y / PLATE_HEIGHT);
                y = yLevel * PLATE_HEIGHT + actualHeight / 2;
            }

            // 强制对齐到积木凸粒网格
            // 凸粒间距为1.0单位，根据积木宽度奇偶性决定对齐方式
            let preferHalfX = (w % 2 === 0);
            let preferHalfZ = (d % 2 === 0);
            
            if (!isFloor && ref && ref.size) {
                // 如果在另一个积木上堆叠，对齐到参考积木的凸粒网格
                const refRot = (ref.rotation || 0) % 4;
                const refW = (refRot % 2 === 0) ? ref.size[0] : ref.size[2];
                const refD = (refRot % 2 === 0) ? ref.size[2] : ref.size[0];
                // 根据参考积木的凸粒数量决定对齐方式
                preferHalfX = (refW % 2 === 0);
                preferHalfZ = (refD % 2 === 0);
            }
            
            // 对齐到0.5或1.0的网格
            x = preferHalfX ? Math.floor(x) + 0.5 : Math.round(x);
            z = preferHalfZ ? Math.floor(z) + 0.5 : Math.round(z);

            return [x, y, z];
        }

        // 移除onMouseMove的hover预览功能，现在使用拖拽预览
        function onMouseMove(event) {
            // 不再显示hover预览，只依赖拖拽预览
            return;
        }

        function onMouseClick(event) {
            if (viewMode === 'preview') return;

            // ignore click caused by camera dragging
            if (controls && controls.wasDragging) {
                controls.wasDragging = false;
                return;
            }

            mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
            mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

            raycaster.setFromCamera(mouse, camera);
            const intersects = raycaster.intersectObjects(scene.children, true).filter((i) => {
                let o = i.object;
                while (o) { if (o.name === 'hoverBrick' || o.name === 'dragPreview') return false; o = o.parent; }
                return true;
            });

            // 移除build模式的点击放置功能，只保留erase和paint模式
            if (toolMode === 'erase' || toolMode === 'paint') {
                for (let intersect of intersects) {
                    let obj = intersect.object;
                    while (obj.parent && !obj.userData.brickId) {
                        obj = obj.parent;
                    }
                    if (obj.userData.brickId) {
                        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                            if (toolMode === 'erase') {
                                window.flutter_inappwebview.callHandler('onRemoveBrick', [obj.userData.brickId]);
                            } else if (toolMode === 'paint') {
                                window.flutter_inappwebview.callHandler('onPaintBrick', [obj.userData.brickId]);
                            }
                        }
                        break;
                    }
                }
            }
        }

        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }

        let firstRender = true;
        function animate() {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
            
            // 首次渲染后移除加载提示
            if (firstRender) {
                firstRender = false;
                const loadingOverlay = document.getElementById('loading-overlay');
                if (loadingOverlay) {
                    loadingOverlay.style.transition = 'opacity 0.3s';
                    loadingOverlay.style.opacity = '0';
                    setTimeout(() => loadingOverlay.remove(), 300);
                }
            }
        }

        // Initialize scene
        init();

        // ========== 长按拖动积木功能 ==========
        let longPressTimer = null;
        let isLongPressing = false;
        let isDraggingBrick = false;
        let draggedBrickId = null;
        let draggedBrickData = null;
        let dragStartPos = { x: 0, y: 0 };
        const LONG_PRESS_DURATION = 500; // 长按时长（毫秒）
        
        function startLongPressDetection(clientX, clientY) {
            if (toolMode !== 'build') return;
            
            dragStartPos = { x: clientX, y: clientY };
            
            longPressTimer = setTimeout(() => {
                // 检测长按位置是否有积木
                const raycaster = new THREE.Raycaster();
                const mouse = new THREE.Vector2();
                mouse.x = (clientX / window.innerWidth) * 2 - 1;
                mouse.y = -(clientY / window.innerHeight) * 2 + 1;
                raycaster.setFromCamera(mouse, camera);
                
                const intersects = raycaster.intersectObjects(scene.children, true);
                
                for (const hit of intersects) {
                    let obj = hit.object;
                    while (obj && !obj.userData.brickId) {
                        obj = obj.parent;
                    }
                    
                    if (obj && obj.userData.brickId) {
                        // 找到积木，开始拖动
                        isLongPressing = true;
                        isDraggingBrick = true;
                        draggedBrickId = obj.userData.brickId;
                        draggedBrickData = bricks.find(b => b.id === draggedBrickId);
                        
                        if (draggedBrickData) {
                            // 禁用 OrbitControls
                            controls.enabled = false;
                            
                            // 从场景中移除原积木（只是视觉上，不从 bricks 数组删除）
                            scene.remove(obj);
                            
                            // 临时从 bricks 数组中移除，避免自己和自己碰撞检测
                            const tempIndex = bricks.indexOf(draggedBrickData);
                            if (tempIndex > -1) {
                                bricks.splice(tempIndex, 1);
                                rebuildOccupancy(bricks);
                            }
                            
                            console.log('[LongPress] Start dragging brick:', draggedBrickId);
                        }
                        break;
                    }
                }
            }, LONG_PRESS_DURATION);
        }
        
        function cancelLongPress() {
            if (longPressTimer) {
                clearTimeout(longPressTimer);
                longPressTimer = null;
            }
            isLongPressing = false;
        }
        
        function updateBrickDrag(clientX, clientY) {
            if (!isDraggingBrick || !draggedBrickData) return;
            
            try {
                // 移除旧预览
                const oldPreview = scene.getObjectByName('dragPreview');
                if (oldPreview) {
                    scene.remove(oldPreview);
                }
                
                // Raycasting 获取交点
                const raycaster = new THREE.Raycaster();
                const mouse = new THREE.Vector2();
                mouse.x = (clientX / window.innerWidth) * 2 - 1;
                mouse.y = -(clientY / window.innerHeight) * 2 + 1;
                raycaster.setFromCamera(mouse, camera);
                
                const intersects = raycaster.intersectObjects(scene.children, true);
                
                if (intersects.length > 0) {
                    const hit = intersects[0];
                    const isFloor = hit.object.name === 'floor';
                    let normal = hit.face ? hit.face.normal.clone() : new THREE.Vector3(0, 1, 0);
                    
                    if (!isFloor) {
                        normal.transformDirection(hit.object.matrixWorld);
                    }
                    
                    let refMeta = null;
                    let refBrick = null;
                    if (!isFloor) {
                        let refObj = hit.object;
                        while (refObj && !refObj.userData.brickId) refObj = refObj.parent;
                        if (refObj && refObj.userData && refObj.userData.size) {
                            refMeta = { size: refObj.userData.size, rotation: refObj.userData.rotation || 0 };
                            const brickId = refObj.userData.brickId;
                            refBrick = bricks.find(b => b.id === brickId);
                        }
                    }
                    
                    const brickRotation = draggedBrickData.rotation || 0;
                    const baseSnap = snapToGrid(hit.point, normal, isFloor, refMeta, refBrick);
                    let candidate = baseSnap;
                    let noOverlap = !willOverlap(candidate, draggedBrickData.size, brickRotation);
                    let supported = hasSupport(candidate, draggedBrickData.size, brickRotation);
                    let valid = noOverlap && supported;
                    
                    // 检查碰撞并自动向上堆叠
                    const highestTop = findHighestCollisionTop(candidate, draggedBrickData.size, brickRotation);
                    
                    if (highestTop > 0 && !noOverlap) {
                        const h = draggedBrickData.size[1];
                        const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
                        
                        let newY = highestTop + actualHeight / 2;
                        const yLevel = Math.round((newY - actualHeight / 2) / PLATE_HEIGHT);
                        newY = yLevel * PLATE_HEIGHT + actualHeight / 2;
                        
                        if (newY - actualHeight / 2 < highestTop) {
                            newY = highestTop + actualHeight / 2;
                        }
                        
                        const upwardCandidate = [candidate[0], newY, candidate[2]];
                        const tryNoOverlap = !willOverlap(upwardCandidate, draggedBrickData.size, brickRotation);
                        
                        if (tryNoOverlap) {
                            candidate = upwardCandidate;
                            valid = true;
                        }
                    }
                    
                    // 如果还是无效，尝试水平偏移
                    if (!valid) {
                        const horizontalOffsets = [
                            [0.5, 0, 0], [-0.5, 0, 0], [0, 0, 0.5], [0, 0, -0.5],
                            [0.5, 0, 0.5], [-0.5, 0, 0.5], [0.5, 0, -0.5], [-0.5, 0, -0.5]
                        ];
                        
                        for (const off of horizontalOffsets) {
                            const tryPos = [candidate[0] + off[0], candidate[1] + off[1], candidate[2] + off[2]];
                            const tryNoOverlap = !willOverlap(tryPos, draggedBrickData.size, brickRotation);
                            const trySupported = hasSupport(tryPos, draggedBrickData.size, brickRotation);
                            if (tryNoOverlap && trySupported) {
                                candidate = tryPos;
                                valid = true;
                                break;
                            }
                        }
                    }
                    
                    // 创建半透明预览
                    const previewColor = valid ? draggedBrickData.color : '#EF4444';
                    const preview = createLegoPiece(
                        candidate, 
                        draggedBrickData.size, 
                        previewColor, 
                        brickRotation, 
                        true, 
                        0.6, 
                        draggedBrickData.hasWheels || false
                    );
                    preview.name = 'dragPreview';
                    scene.add(preview);
                }
            } catch(e) {
                console.error('[LongPress] Preview error:', e);
            }
        }
        
        function endBrickDrag(clientX, clientY) {
            if (isDraggingBrick && draggedBrickData && draggedBrickId) {
                console.log('[LongPress] End dragging brick:', draggedBrickId);
                
                // 移除预览
                const preview = scene.getObjectByName('dragPreview');
                if (preview) {
                    scene.remove(preview);
                }
                
                // 使用与 placeBrickAtScreenPosition 相同的逻辑计算最终位置
                try {
                    const raycaster = new THREE.Raycaster();
                    const mouse = new THREE.Vector2();
                    mouse.x = (clientX / window.innerWidth) * 2 - 1;
                    mouse.y = -(clientY / window.innerHeight) * 2 + 1;
                    raycaster.setFromCamera(mouse, camera);
                    
                    const intersects = raycaster.intersectObjects(scene.children, true);
                    
                    if (intersects.length > 0) {
                        const hit = intersects[0];
                        const isFloor = hit.object.name === 'floor';
                        let normal = hit.face ? hit.face.normal.clone() : new THREE.Vector3(0, 1, 0);
                        
                        if (!isFloor) {
                            normal.transformDirection(hit.object.matrixWorld);
                        }
                        
                        let refMeta = null;
                        let refBrick = null;
                        if (!isFloor) {
                            let refObj = hit.object;
                            while (refObj && !refObj.userData.brickId) refObj = refObj.parent;
                            if (refObj && refObj.userData && refObj.userData.size) {
                                refMeta = { size: refObj.userData.size, rotation: refObj.userData.rotation || 0 };
                                const brickId = refObj.userData.brickId;
                                refBrick = bricks.find(b => b.id === brickId);
                            }
                        }
                        
                        const brickRotation = draggedBrickData.rotation || 0;
                        const baseSnap = snapToGrid(hit.point, normal, isFloor, refMeta, refBrick);
                        let candidate = baseSnap;
                        let noOverlap = !willOverlap(candidate, draggedBrickData.size, brickRotation);
                        let supported = hasSupport(candidate, draggedBrickData.size, brickRotation);
                        let valid = noOverlap && supported;
                        
                        console.log('[Drag] Base position:', candidate, 'overlap:', !noOverlap, 'supported:', supported, 'valid:', valid);
                        
                        // 总是检查碰撞区域最高点，如果有碰撞就向上堆叠
                        const highestTop = findHighestCollisionTop(candidate, draggedBrickData.size, brickRotation);
                        console.log('[Drag] Highest collision top at Y:', highestTop);
                        
                        if (highestTop > 0 && !noOverlap) {
                            const h = draggedBrickData.size[1];
                            const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
                            
                            let newY = highestTop + actualHeight / 2;
                            const yLevel = Math.round((newY - actualHeight / 2) / PLATE_HEIGHT);
                            newY = yLevel * PLATE_HEIGHT + actualHeight / 2;
                            
                            if (newY - actualHeight / 2 < highestTop) {
                                newY = highestTop + actualHeight / 2;
                            }
                            
                            const upwardCandidate = [candidate[0], newY, candidate[2]];
                            console.log('[Drag] Adjusted to:', upwardCandidate);
                            
                            const tryNoOverlap = !willOverlap(upwardCandidate, draggedBrickData.size, brickRotation);
                            
                            if (tryNoOverlap) {
                                candidate = upwardCandidate;
                                valid = true;
                                console.log('[Drag] Upward placement SUCCESS');
                            } else {
                                console.log('[Drag] Upward placement FAILED - still has overlap');
                            }
                        }
                        
                        if (valid) {
                            // 使用 onMoveBrick 更新位置
                            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                                window.flutter_inappwebview.callHandler('onMoveBrick', {
                                    id: draggedBrickId,
                                    position: candidate
                                });
                            }
                        } else {
                            // 放置失败，恢复原积木
                            bricks.push(draggedBrickData);
                            rebuildOccupancy(bricks);
                            updateBricks(bricks);
                        }
                    } else {
                        // 没有交点，恢复原积木
                        bricks.push(draggedBrickData);
                        rebuildOccupancy(bricks);
                        updateBricks(bricks);
                    }
                } catch(e) {
                    console.error('[LongPress] Error placing brick:', e);
                    // 出错时恢复原积木
                    bricks.push(draggedBrickData);
                    rebuildOccupancy(bricks);
                    updateBricks(bricks);
                }
                
                // 重新启用 OrbitControls
                controls.enabled = true;
            }
            
            isDraggingBrick = false;
            draggedBrickId = null;
            draggedBrickData = null;
            cancelLongPress();
        }
        
        // 触摸事件监听
        renderer.domElement.addEventListener('touchstart', function(e) {
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                startLongPressDetection(touch.clientX, touch.clientY);
            }
        }, { passive: false });
        
        renderer.domElement.addEventListener('touchmove', function(e) {
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                const dx = touch.clientX - dragStartPos.x;
                const dy = touch.clientY - dragStartPos.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                // 如果移动超过阈值，取消长按检测
                if (distance > 10 && !isDraggingBrick) {
                    cancelLongPress();
                }
                
                // 如果正在拖动积木，更新位置
                if (isDraggingBrick) {
                    updateBrickDrag(touch.clientX, touch.clientY);
                    e.preventDefault();
                }
            }
        }, { passive: false });
        
        renderer.domElement.addEventListener('touchend', function(e) {
            if (isDraggingBrick) {
                if (e.changedTouches.length > 0) {
                    const t = e.changedTouches[0];
                    endBrickDrag(t.clientX, t.clientY);
                }
                e.preventDefault();
            } else {
                cancelLongPress();
                // 正常点击逻辑
                if (e.changedTouches.length > 0) {
                    const t = e.changedTouches[0];
                    onMouseClick({ clientX: t.clientX, clientY: t.clientY, preventDefault: () => e.preventDefault() });
                }
            }
            e.preventDefault();
        }, { passive: false });
        
        // 鼠标事件监听（用于桌面测试）
        renderer.domElement.addEventListener('mousedown', function(e) {
            startLongPressDetection(e.clientX, e.clientY);
        });
        
        renderer.domElement.addEventListener('mousemove', function(e) {
            if (isDraggingBrick) {
                updateBrickDrag(e.clientX, e.clientY);
            } else {
                const dx = e.clientX - dragStartPos.x;
                const dy = e.clientY - dragStartPos.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                if (distance > 10) {
                    cancelLongPress();
                }
            }
        });
        
        renderer.domElement.addEventListener('mouseup', function(e) {
            if (isDraggingBrick) {
                endBrickDrag(e.clientX, e.clientY);
            } else {
                cancelLongPress();
            }
        });

        // Mouse/touch events for interaction
        // Do NOT update preview on move to avoid following while dragging
        renderer.domElement.addEventListener('click', onMouseClick, { passive: false });
        // Global functions for Flutter communication
        window.updateScene = function(data) {
            bricks = data.bricks || [];
            toolMode = data.toolMode || 'build';
            selectedShape = data.selectedShape || { size: [2, 1, 4] };
            selectedColor = data.selectedColor || '#ef4444';
            rotation = data.rotation || 0;
            viewMode = data.viewMode || 'editor';
            showGrid = data.showGrid !== false;
            showShadows = data.showShadows !== false;
            
            updateBricks(bricks);
            rebuildOccupancy(bricks);
            
            // 更新网格显示状态
            const gridHelper = scene.getObjectByName('GridHelper');
            if (gridHelper) {
                gridHelper.visible = showGrid;
            }
            
            // 更新阴影显示状态
            const directionalLight = scene.children.find(child => 
                child instanceof THREE.DirectionalLight && child.castShadow
            );
            if (directionalLight) {
                directionalLight.visible = showShadows;
            }
            renderer.shadowMap.enabled = showShadows;
        };

        // 拖放直接放置积木的函数
        window.placeBrickAtScreenPosition = function(normalizedX, normalizedY) {
            try {
                if (!raycaster || !camera || !floorPlane) {
                    console.error('Scene not ready for drag-drop');
                    return false;
                }
                
                const mouse = new THREE.Vector2(normalizedX, normalizedY);
                raycaster.setFromCamera(mouse, camera);
                
                // 与场景对象相交（地面+已有积木）
                const intersects = raycaster.intersectObjects(scene.children, true).filter((i) => {
                    let o = i.object;
                    while (o) {
                        if (o.name === 'hoverBrick') return false;
                        o = o.parent;
                    }
                    return true;
                });
                
                if (intersects.length === 0) return false;
                
                const hit = intersects[0];
                const isFloor = hit.object === floorPlane;
                let normal = new THREE.Vector3(0, 1, 0);
                if (!isFloor && hit.face) {
                    normal = hit.face.normal.clone();
                    normal.transformDirection(hit.object.matrixWorld);
                }
                
                let refMeta = null;
                let refBrick = null;
                if (!isFloor) {
                    let refObj = hit.object;
                    while (refObj && !refObj.userData.brickId) refObj = refObj.parent;
                    if (refObj && refObj.userData && refObj.userData.size) {
                        refMeta = { size: refObj.userData.size, rotation: refObj.userData.rotation || 0 };
                        const brickId = refObj.userData.brickId;
                        refBrick = bricks.find(b => b.id === brickId);
                    }
                }
                
                const baseSnap = snapToGrid(hit.point, normal, isFloor, refMeta, refBrick);
                let candidate = baseSnap;
                let noOverlap = !willOverlap(candidate, selectedShape.size, rotation);
                let supported = hasSupport(candidate, selectedShape.size, rotation);
                let valid = noOverlap && supported;
                
                console.log('[Drag] Base position:', candidate, 'overlap:', !noOverlap, 'supported:', supported, 'valid:', valid);
                
                // 总是检查碰撞区域最高点，如果有碰撞就向上堆叠
                const highestTop = findHighestCollisionTop(candidate, selectedShape.size, rotation);
                console.log('[Drag] Highest collision top at Y:', highestTop);
                
                if (highestTop > 0 && !noOverlap) {
                    // 有碰撞，将积木放置在最高碰撞点之上
                    const h = selectedShape.size[1];
                    const actualHeight = (h <= PLATE_RATIO + 0.01) ? PLATE_HEIGHT : BRICK_HEIGHT;
                    
                    // 将积木放置在最高碰撞点之上，确保底部紧贴顶部
                    let newY = highestTop + actualHeight / 2;
                    
                    // 对齐到 PLATE_HEIGHT 网格，但确保至少在最高点上方
                    const yLevel = Math.round((newY - actualHeight / 2) / PLATE_HEIGHT);
                    newY = yLevel * PLATE_HEIGHT + actualHeight / 2;
                    
                    // 确保新位置不低于最高点
                    if (newY - actualHeight / 2 < highestTop) {
                        newY = highestTop + actualHeight / 2;
                    }
                    
                    const upwardCandidate = [candidate[0], newY, candidate[2]];
                    console.log('[Drag] Adjusted to:', upwardCandidate);
                    
                    const tryNoOverlap = !willOverlap(upwardCandidate, selectedShape.size, rotation);
                    
                    // 对于向上堆叠，只需要检查无重叠，不需要检查支撑（因为我们在最高点上方）
                    if (tryNoOverlap) {
                        candidate = upwardCandidate;
                        valid = true;
                        console.log('[Drag] Upward placement SUCCESS');
                    } else {
                        console.log('[Drag] Upward placement FAILED - still has overlap');
                    }
                }
                
                // 如果还是无效，尝试水平偏移
                if (!valid) {
                    console.log('[Drag] Trying horizontal offsets...');
                    const horizontalOffsets = [
                        [0.5, 0, 0], [-0.5, 0, 0], [0, 0, 0.5], [0, 0, -0.5],
                        [0.5, 0, 0.5], [-0.5, 0, 0.5], [0.5, 0, -0.5], [-0.5, 0, -0.5]
                    ];
                    
                    for (const off of horizontalOffsets) {
                        const tryPos = [candidate[0] + off[0], candidate[1] + off[1], candidate[2] + off[2]];
                        const tryNoOverlap = !willOverlap(tryPos, selectedShape.size, rotation);
                        const trySupported = hasSupport(tryPos, selectedShape.size, rotation);
                        if (tryNoOverlap && trySupported) {
                            candidate = tryPos;
                            valid = true;
                            console.log('[Drag] Horizontal offset SUCCESS:', tryPos);
                            break;
                        }
                    }
                }
                
                if (valid) {
                    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        window.flutter_inappwebview.callHandler('onAddBrick', candidate);
                    }
                    return true;
                }
                return false;
            } catch(e) {
                console.error('placeBrickAtScreenPosition error:', e);
                return false;
            }
        };

        // Error handling
        window.addEventListener('error', function(e) {
            console.error('JavaScript error:', e.error);
        });
    </script>
</body>
</html>
    ''';
  }

  void _initializeScene() {
    if (_webViewController != null) {
      _webViewController!.addJavaScriptHandler(
        handlerName: 'onAddBrick',
        callback: (args) {
          try {
            // args could be [x, y, z] or [[x, y, z]] depending on the bridge
            List<double> pos;
            if (args.isNotEmpty && args[0] is List) {
              pos = (args[0] as List).map((e) => (e as num).toDouble()).toList().cast<double>();
            } else {
              pos = args.map((e) => (e as num).toDouble()).toList().cast<double>();
            }
            if (pos.length != 3) {
              throw Exception('Invalid position from JS: $args');
            }
            final brick = BrickData(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              position: pos,
              color: widget.selectedColor,
              size: widget.selectedShape.size,
              rotation: widget.rotation,
            );
            widget.onAddBrick(brick);
          } catch (e) {
            debugPrint('Error in onAddBrick: $e');
          }
        },
      );

      _webViewController!.addJavaScriptHandler(
        handlerName: 'onRemoveBrick',
        callback: (args) {
          try {
            // 处理嵌套数组的情况
            String brickId;
            if (args.isNotEmpty) {
              if (args[0] is List) {
                brickId = args[0][0].toString();
              } else {
                brickId = args[0].toString();
              }
              widget.onRemoveBrick(brickId);
            }
          } catch (e) {
            debugPrint('Error in onRemoveBrick: $e, args: $args');
          }
        },
      );

      _webViewController!.addJavaScriptHandler(
        handlerName: 'onPaintBrick',
        callback: (args) {
          try {
            // 处理嵌套数组的情况
            String brickId;
            if (args.isNotEmpty) {
              if (args[0] is List) {
                brickId = args[0][0].toString();
              } else {
                brickId = args[0].toString();
              }
              widget.onPaintBrick(brickId);
            }
          } catch (e) {
            debugPrint('Error in onPaintBrick: $e, args: $args');
          }
        },
      );

      _webViewController!.addJavaScriptHandler(
        handlerName: 'onMoveBrick',
        callback: (args) {
          try {
            // args 应该是 { id: string, position: [x, y, z] }
            if (args.isNotEmpty) {
              Map<String, dynamic> data;
              if (args[0] is Map) {
                data = Map<String, dynamic>.from(args[0]);
              } else {
                throw Exception('Expected Map in onMoveBrick args');
              }
              
              final brickId = data['id'].toString();
              final position = (data['position'] as List)
                  .map((e) => (e as num).toDouble())
                  .toList()
                  .cast<double>();
              
              if (position.length != 3) {
                throw Exception('Invalid position in onMoveBrick: $position');
              }
              
              widget.onMoveBrick(brickId, position);
            }
          } catch (e) {
            debugPrint('Error in onMoveBrick: $e, args: $args');
          }
        },
      );

      _updateScene();
    }
  }

  void _updateScene() {
    if (_webViewController != null) {
      try {
        final bricksList = widget.bricks.map((b) => b.toJson()).toList();
        final bricksJson = jsonEncode(bricksList);
        
        final adjustedSize = widget.isPlateMode 
            ? [widget.selectedShape.size[0], 0.33, widget.selectedShape.size[2]]
            : widget.selectedShape.size;
        
        _webViewController!.evaluateJavascript(source: '''
          try {
            window.updateScene({
              bricks: $bricksJson,
              toolMode: "${widget.toolMode.name}",
              selectedShape: { size: [${adjustedSize.join(',')}], hasWheels: ${widget.selectedShape.hasWheels} },
              selectedColor: "${widget.selectedColor}",
              rotation: ${widget.rotation},
              viewMode: "${widget.viewMode.name}",
              showGrid: ${widget.showGrid},
              showShadows: ${widget.showShadows ? 'true' : 'false'}
            });
          } catch(e) {
            console.error('Scene update error:', e.message);
          }
        ''');
      } catch (e) {
        debugPrint('Error in _updateScene: $e');
      }
    }
  }

  Future<void> captureAndShare() async {
    if (_webViewController == null) {
      debugPrint('WebView controller not ready');
      return;
    }

    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在生成截图...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 截取 WebView 截图
      final screenshot = await _webViewController!.takeScreenshot();
      
      if (screenshot == null) {
        throw Exception('Failed to capture screenshot');
      }

      // 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/lego_creation_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(screenshot);

      // 使用 share_plus 分享
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '我的积木作品 🧱',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('截图已生成！'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing/sharing screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(LegoWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateScene();
  }
}