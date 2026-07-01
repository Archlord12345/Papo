import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.borderColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? (isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.05)),
              width: 1.0,
            ),
            gradient: LinearGradient(
              colors: gradientColors ?? (isDark 
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.01),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.3),
                    ]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
