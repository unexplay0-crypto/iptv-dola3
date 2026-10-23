import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Skeleton screen monocromático com shimmer (permite foco durante carga).
class SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonCard(
      {super.key,
      required this.width,
      required this.height,
      this.borderRadius = 8});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
                Color.lerp(AppTheme.skeleton, AppTheme.skeletonShimmer,
                        _ctrl.value) ??
                    AppTheme.skeletonShimmer,
                AppTheme.skeleton,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grid de skeletons com proporção de pôster (2:3) — 4 colunas.
class SkeletonGrid extends StatelessWidget {
  final int count;
  const SkeletonGrid({super.key, this.count = 12});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(
          width: double.infinity,
          height: double.infinity,
          borderRadius: AppTheme.radiusPoster),
    );
  }
}
