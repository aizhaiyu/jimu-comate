import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app/pages/lego_studio_page.dart';
import 'package:app/pages/my_works_page.dart';
import 'package:app/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;
  
  // 3D模型查看器的HTML内容
  static const String _get3DViewerHTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; overflow: hidden; background: transparent !important; }
        #canvas-container { width: 100%; height: 100%; position: relative; }
        canvas { display: block; width: 100% !important; height: 100% !important; background: transparent !important; }
    </style>
</head>
<body>
    <div id="canvas-container"></div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script>
        let scene, camera, renderer, brickGroup;
        let isRotating = true;
        
        function init() {
            scene = new THREE.Scene();
            const container = document.getElementById('canvas-container');
            const aspect = container.clientWidth / container.clientHeight;
            camera = new THREE.PerspectiveCamera(35, aspect, 0.1, 1000);
            camera.position.set(0, 1, 5);
            camera.lookAt(0, 0, 0);
            
            renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, premultipliedAlpha: false });
            renderer.setSize(container.clientWidth, container.clientHeight);
            renderer.setPixelRatio(window.devicePixelRatio || 1);
            renderer.setClearColor(0x000000, 0);
            container.appendChild(renderer.domElement);
            
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
            scene.add(ambientLight);
            const directionalLight1 = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight1.position.set(2, 3, 2);
            scene.add(directionalLight1);
            const directionalLight2 = new THREE.DirectionalLight(0xFFCC99, 0.4);
            directionalLight2.position.set(-2, 1, -2);
            scene.add(directionalLight2);
            
            createBrickLogo();
            addInteraction();
            animate();
            window.addEventListener('resize', onWindowResize);
        }
        
        function createBrickLogo() {
            brickGroup = new THREE.Group();
            const material = new THREE.MeshPhongMaterial({ color: 0xFF8C42, shininess: 100, specular: 0xFFAA66 });
            const darkMaterial = new THREE.MeshPhongMaterial({ color: 0xF97316, shininess: 100, specular: 0xFFAA66 });
            const bodyGeometry = new THREE.BoxGeometry(2, 0.6, 1);
            const body = new THREE.Mesh(bodyGeometry, material);
            brickGroup.add(body);
            
            const studGeometry = new THREE.CylinderGeometry(0.12, 0.12, 0.18, 16);
            const positions = [
                [-0.75, -0.25], [-0.25, -0.25], [0.25, -0.25], [0.75, -0.25],
                [-0.75,  0.25], [-0.25,  0.25], [0.25,  0.25], [0.75,  0.25]
            ];
            positions.forEach(([x, z]) => {
                const stud = new THREE.Mesh(studGeometry, darkMaterial);
                stud.position.set(x, 0.39, z);
                brickGroup.add(stud);
            });
            
            brickGroup.rotation.x = 0.8;
            brickGroup.rotation.y = 0.3;
            brickGroup.rotation.z = 0;
            scene.add(brickGroup);
        }
        
        function addInteraction() {
            const canvas = renderer.domElement;
            let isDragging = false;
            let previousMousePosition = { x: 0, y: 0 };
            
            canvas.addEventListener('mousedown', onPointerDown);
            canvas.addEventListener('touchstart', onPointerDown);
            canvas.addEventListener('mousemove', onPointerMove);
            canvas.addEventListener('touchmove', onPointerMove);
            canvas.addEventListener('mouseup', onPointerUp);
            canvas.addEventListener('touchend', onPointerUp);
            canvas.addEventListener('mouseleave', onPointerUp);
            
            function onPointerDown(e) {
                isDragging = true;
                isRotating = false;
                const point = getPointerPosition(e);
                previousMousePosition = { x: point.x, y: point.y };
            }
            
            function onPointerMove(e) {
                if (!isDragging) return;
                e.preventDefault();
                const point = getPointerPosition(e);
                const deltaX = point.x - previousMousePosition.x;
                const deltaY = point.y - previousMousePosition.y;
                brickGroup.rotation.y += deltaX * 0.01;
                brickGroup.rotation.x += deltaY * 0.01;
                previousMousePosition = { x: point.x, y: point.y };
            }
            
            function onPointerUp() {
                isDragging = false;
                setTimeout(() => { if (!isDragging) isRotating = true; }, 2000);
            }
            
            function getPointerPosition(e) {
                if (e.touches && e.touches.length > 0) {
                    return { x: e.touches[0].clientX, y: e.touches[0].clientY };
                }
                return { x: e.clientX, y: e.clientY };
            }
        }
        
        function animate() {
            requestAnimationFrame(animate);
            if (isRotating && brickGroup) {
                brickGroup.rotation.y += 0.003;
                brickGroup.position.y = Math.sin(Date.now() * 0.001) * 0.05;
            }
            renderer.render(scene, camera);
        }
        
        function onWindowResize() {
            const container = document.getElementById('canvas-container');
            const aspect = container.clientWidth / container.clientHeight;
            camera.aspect = aspect;
            camera.updateProjectionMatrix();
            renderer.setSize(container.clientWidth, container.clientHeight);
        }
        
        init();
    </script>
</body>
</html>
  ''';

  @override
  void initState() {
    super.initState();
    
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeInOut,
    ));
    
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutBack,
    ));
    
    _buttonFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
    
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimationSequence();
  }
  
  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _buttonController.forward();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.03,
            ),
            child: Row(
              children: [
                // 左侧标题区域
                Expanded(
                  flex: 2,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _titleController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: _buildTitleSection(screenWidth, screenHeight),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // 右侧按钮区域
                Expanded(
                  flex: 3,
                  child: AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _buttonFade,
                        child: SlideTransition(
                          position: _buttonSlide,
                          child: _buildGameButtons(screenWidth, screenHeight),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleSection(double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.25,
          height: screenWidth * 0.25,
          child: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _get3DViewerHTML,
              mimeType: 'text/html',
              encoding: 'utf-8',
            ),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              supportZoom: false,
              disableContextMenu: true,
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
              useHybridComposition: true,
              javaScriptEnabled: true,
              domStorageEnabled: true,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF3B82F6),
            ],
          ).createShader(bounds),
          child: const Text(
            '积木工坊',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          '让创意自由流动',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGameButtons(double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _GameButton(
                icon: Icons.construction,
                title: '积木搭建',
                subtitle: '创建你的作品',
                color: const Color(0xFF10B981),
                onPressed: () => _navigateToLegoStudio(),
                delay: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GameButton(
                icon: Icons.collections_bookmark,
                title: '我的作品',
                subtitle: '查看收藏',
                color: const Color(0xFFF59E0B),
                onPressed: () => _showMyWorks(),
                delay: 100,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _GameButton(
                icon: Icons.school,
                title: '教学模式',
                subtitle: '学习技巧',
                color: const Color(0xFF8B5CF6),
                onPressed: () => _showTutorial(),
                delay: 200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GameButton(
                icon: Icons.settings,
                title: '设置',
                subtitle: '偏好设置',
                color: const Color(0xFF6B7280),
                onPressed: () => _showSettings(),
                delay: 300,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _navigateToLegoStudio() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LegoStudioPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _showMyWorks() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MyWorksPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _showTutorial() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          const LegoStudioPage(isTutorialMode: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _showSettings() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
}

class _GameButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;
  final int delay;
  
  const _GameButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + widget.delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return GestureDetector(
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) {
                  _controller.reverse();
                  widget.onPressed();
                },
                onTapCancel: () => _controller.reverse(),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color,
                          widget.color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}