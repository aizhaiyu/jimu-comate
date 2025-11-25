import 'package:flutter/material.dart';

/// 动画按钮组件 - 带有动画效果的交互按钮
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Duration? animationDuration;
  final Duration? delay;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.animationDuration,
    this.delay,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glow = Tween<double>(
      begin: 1.0,
      end: 1.2,
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
      duration: widget.delay ?? const Duration(milliseconds: 600),
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
                    width: widget.width,
                    height: widget.height,
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor,
                          widget.backgroundColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.backgroundColor.withOpacity(0.3 * _glow.value),
                          blurRadius: 20 * _glow.value,
                          spreadRadius: 2 * _glow.value,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: widget.foregroundColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        child: widget.child,
                      ),
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