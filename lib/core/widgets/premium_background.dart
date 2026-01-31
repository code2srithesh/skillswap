import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  final bool useLightMode;

  const PremiumBackground({
    super.key,
    required this.child,
    this.useLightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark && !useLightMode) {
      // Light mode - subtle gradient
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFEEF2FF),
              const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: child,
      );
    }

    // Dark mode - Premium mesh gradient with VISIBLE glow
    return Stack(
      children: [
        // 1. Base Dark Layer - Rich deep background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0D12), Color(0xFF12121A), Color(0xFF0D0D12)],
            ),
          ),
        ),

        // 2. Ambient Glow Orbs - BRIGHTER for visibility
        Positioned(
          top: -100,
          right: -50,
          child: _GlowOrb(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            size: 400,
            blur: 150,
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _GlowOrb(
            color: const Color(0xFFEC4899).withOpacity(0.18),
            size: 350,
            blur: 120,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: -100,
          child: _GlowOrb(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            size: 280,
            blur: 100,
          ),
        ),
        // Extra glow for depth
        Positioned(
          top: MediaQuery.of(context).size.height * 0.6,
          left: -80,
          child: _GlowOrb(
            color: const Color(0xFF10B981).withOpacity(0.1),
            size: 200,
            blur: 80,
          ),
        ),

        // 3. Subtle vignette overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.transparent, Colors.black.withOpacity(0.15)],
              ),
            ),
          ),
        ),

        // 4. The Content
        child,
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
          BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2),
        ],
      ),
    );
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
