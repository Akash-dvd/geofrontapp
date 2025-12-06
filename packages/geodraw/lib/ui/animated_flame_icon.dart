import 'package:flutter/material.dart';

/// Animated flame icon for displaying points at infinity (GeoInf)
/// Creates a dramatic burning/flaming effect with flickering animation
class AnimatedFlameIcon extends StatefulWidget {
  final double size;
  final bool showGlow;

  const AnimatedFlameIcon({
    super.key,
    this.size = 16,
    this.showGlow = true,
  });

  @override
  State<AnimatedFlameIcon> createState() => _AnimatedFlameIconState();
}

class _AnimatedFlameIconState extends State<AnimatedFlameIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flickerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with duration for natural flickering
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    // Flicker animation - random opacity changes
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.8, end: 1.0), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.9, end: 1.0), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.85, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Scale animation - slight size variations
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.05, end: 0.98), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.98, end: 1.02), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.02, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Glow animation - pulsing glow effect
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.3, end: 0.5), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.5, end: 0.4), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.4, end: 0.6), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.6, end: 0.3), weight: 1),
    ]).animate(CurvedAnimation(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _flickerAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Animated glow effect
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B35)
                              .withOpacity(_glowAnimation.value),
                          blurRadius: widget.size * 0.8,
                          spreadRadius: widget.size * 0.2,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFB347)
                              .withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: widget.size * 1.2,
                          spreadRadius: widget.size * 0.1,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // Animated gradient colors that flicker
                      Color.lerp(
                        const Color(0xFFFF6B35),
                        const Color(0xFFFF8C42),
                        _flickerAnimation.value * 0.5,
                      )!,
                      Color.lerp(
                        const Color(0xFFFF8C42),
                        const Color(0xFFFFB347),
                        _flickerAnimation.value * 0.3,
                      )!,
                      const Color(0xFFFFB347),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      const Color(0xFFFF4444),
                      const Color(0xFFFF6B35),
                      _flickerAnimation.value * 0.3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.375,
                      height: widget.size * 0.375,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFFFFF700),
                          const Color(0xFFFFB347),
                          _flickerAnimation.value * 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
