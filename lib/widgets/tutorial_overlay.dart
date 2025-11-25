import 'package:flutter/material.dart';

/// 新手教学覆盖层 - 提供交互式的使用指导
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _handController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  
  late Animation<Offset> _handPosition;
  late Animation<double> _handScale;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFade;
  
  @override
  void initState() {
    super.initState();
    
    // 手势动画控制器
    _handController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 文字淡入控制器
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _setupAnimations();
    _startAnimations();
  }
  
  void _setupAnimations() {
    // 手势位置动画：从左侧积木区域到画布中心
    _handPosition = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.15, 0.5),
          end: const Offset(0.15, 0.5),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30.0, // 停留在积木上
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.15, 0.5),
          end: const Offset(0.5, 0.5),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0, // 拖拽到画布
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.5, 0.5),
          end: const Offset(0.5, 0.5),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20.0, // 停留在画布上
      ),
    ]).animate(_handController);
    
    // 手势缩放动画：模拟按压效果
    _handScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0, // 按下
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0, // 保持按压
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50.0, // 拖拽中
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0, // 松开
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0, // 恢复
      ),
    ]).animate(_handController);
    
    // 脉冲动画
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
    
    // 文字淡入
    _textFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() {
    _textController.forward();
    
    // 循环播放手势动画
    _handController.repeat();
    _pulseController.repeat();
  }
  
  @override
  void dispose() {
    _handController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // 半透明背景层（完全穿透）
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
        
        // 高亮区域：左侧积木库（完全穿透）
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: size.width * 0.25,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.4 + _pulseAnimation.value * 0.4),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3 + _pulseAnimation.value * 0.3),
                        blurRadius: 25 + _pulseAnimation.value * 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // 高亮区域：画布中心（完全穿透）
        Positioned(
          left: size.width * 0.35,
          top: size.height * 0.35,
          width: size.width * 0.3,
          height: size.height * 0.3,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.4 + _pulseAnimation.value * 0.4),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3 + _pulseAnimation.value * 0.3),
                        blurRadius: 25 + _pulseAnimation.value * 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // 动画手势（完全穿透）
        AnimatedBuilder(
          animation: Listenable.merge([_handController, _handPosition, _handScale]),
          builder: (context, child) {
            final position = _handPosition.value;
            return Positioned(
              left: size.width * position.dx - 30,
              top: size.height * position.dy - 30,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: _handScale.value,
                  child: _HandIcon(),
                ),
              ),
            );
          },
        ),
        
        // 顶部提示文字（完全穿透）
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _textFade,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.touch_app,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '新手教学',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '尝试操作：\n① 长按左侧积木\n② 拖拽到画布\n③ 松手放置',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // 跳过按钮（唯一可点击的元素）
        Positioned(
          bottom: 40,
          right: 40,
          child: FadeTransition(
            opacity: _textFade,
            child: ElevatedButton.icon(
              onPressed: widget.onSkip,
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 18),
              label: const Text(
                '跳过教学',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
            ),
          ),
        ),
        
        // 操作提示（完全穿透）
        Positioned(
          bottom: 40,
          left: 40,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _textFade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.blue.shade300,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '现在试试操作吧！',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 手指图标组件
class _HandIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层脉冲圈
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          // 手指图标
          const Icon(
            Icons.touch_app,
            color: Color(0xFF3B82F6),
            size: 32,
          ),
        ],
      ),
    );
  }
}
