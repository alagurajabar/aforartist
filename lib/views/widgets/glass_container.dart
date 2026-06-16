import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = AppTheme.glassBlur,
    this.borderRadius = 16.0,
    this.backgroundColor = AppTheme.glassBackground,
    this.borderColor = AppTheme.glassBorder,
    this.padding,
    this.margin,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
