import 'dart:ui';
import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  final Widget child;
  final bool useLightMode;

  const PremiumBackground({
    super.key,
    required this.child,
    this.useLightMode = false,
  });

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous loop animation for smooth ambient floating effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Rich base gradient backgrounds
    final darkDecoration = const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF040408), Color(0xFF0D0D15), Color(0xFF040408)],
      ),
    );

    final lightDecoration = const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFAFBFD), Color(0xFFEFF3FF), Color(0xFFFAFBFD)],
      ),
    );

    return Stack(
      children: [
        // 1. Base Layer
        Positioned.fill(
          child: Container(
            decoration: isDark ? darkDecoration : lightDecoration,
          ),
        ),

        // 2. Animated Ambient Glow Orbs
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * 2 * pi;
              return Stack(
                children: [
                  // Top-Right Pulsing Orb
                  Positioned(
                    top: -120 + sin(angle) * 70,
                    right: -70 + cos(angle) * 50,
                    child: _GlowOrb(
                      color: isDark
                          ? const Color(0xFF6366F1).withOpacity(0.26)
                          : const Color(0xFF818CF8).withOpacity(0.14),
                      size: 450,
                      blur: 150,
                    ),
                  ),
                  // Bottom-Left Pulsing Orb
                  Positioned(
                    bottom: -80 + cos(angle) * 60,
                    left: -80 + sin(angle) * 70,
                    child: _GlowOrb(
                      color: isDark
                          ? const Color(0xFFEC4899).withOpacity(0.20)
                          : const Color(0xFFF472B6).withOpacity(0.12),
                      size: 400,
                      blur: 130,
                    ),
                  ),
                  // Mid-Right Pulsing Orb
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.32 + cos(angle + 1.8) * 80,
                    right: -120 + sin(angle + 1.8) * 60,
                    child: _GlowOrb(
                      color: isDark
                          ? const Color(0xFF8B5CF6).withOpacity(0.18)
                          : const Color(0xFF38BDF8).withOpacity(0.10),
                      size: 320,
                      blur: 110,
                    ),
                  ),
                  // Mid-Left Pulsing Orb
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.22 + sin(angle - 1.8) * 60,
                    left: -90 + cos(angle - 1.8) * 50,
                    child: _GlowOrb(
                      color: isDark
                          ? const Color(0xFF10B981).withOpacity(0.14)
                          : const Color(0xFF2DD4BF).withOpacity(0.08),
                      size: 240,
                      blur: 90,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 3. Apple/Tesla Inspired Pulsing Tech Grid Overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _TechGridPainter(_controller.value, isDark),
              );
            },
          ),
        ),

        // 4. Ambient Vignette shadow for high-fidelity depth
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                ],
              ),
            ),
          ),
        ),

        // 5. App Content
        widget.child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _GlowOrb({required this.color, required this.size, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }
}

class _TechGridPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _TechGridPainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = sin(animationValue * 2 * pi);
    
    // Grid Lines paint
    final paint = Paint()
      ..color = (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5))
          .withOpacity(isDark ? (0.015 + 0.010 * pulse) : (0.025 + 0.015 * pulse))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double gridSize = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Glowing intersections paint
    final dotPaint = Paint()
      ..color = (isDark ? const Color(0xFFEC4899) : const Color(0xFF6366F1))
          .withOpacity(isDark ? (0.04 + 0.025 * cos(animationValue * 2 * pi)) : (0.06 + 0.03 * cos(animationValue * 2 * pi)))
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize * 2) {
      for (double y = 0; y < size.height; y += gridSize * 2) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TechGridPainter oldDelegate) {
    return oldDelegate.animationValue != oldDelegate.animationValue ||
        oldDelegate.isDark != isDark;
  }
}

/// Premium Glassmorphism Card with blur effect
class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;
  final bool hasGlow;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E).withOpacity(0.9),
                      const Color(0xFF16162A).withOpacity(0.85),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6366F1).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              if (hasGlow && isDark)
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              if (hasGlow && !isDark)
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return BouncyTap(onTap: onTap!, child: card);
    }
    return card;
  }
}

/// Bouncy tap animation wrapper
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  const BouncyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.97,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Staggered fade-slide animation for list items
class StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDuration;
  final Duration staggerDelay;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDuration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 80),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            baseDuration.inMilliseconds + (index * staggerDelay.inMilliseconds),
      ),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }
}

/// Premium Avatar with gradient border
class PremiumAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;

  const PremiumAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F0F1A)
              : Colors.white,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive layout helper
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1024 && desktop != null) {
      return desktop!;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
