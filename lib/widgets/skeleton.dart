import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Skeleton screen monocromático com shimmer (permite foco durante carga).
class SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonCard({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.skeleton,
                Color.lerp(AppTheme.skeleton, AppTheme.skeletonShimmer, _ctrl.value) ?? AppTheme.skeletonShimmer,
                AppTheme.skeleton,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int count;
  const SkeletonGrid({super.key, this.count = 12});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(count, (_) => const SkeletonCard(width: 140, height: 200)),
    );
  }
}
