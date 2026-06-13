import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class RemedyCardSkeleton extends StatelessWidget {
  const RemedyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFFAFAFA),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 90, color: Colors.white),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 15, width: double.infinity, decoration: _box),
                  const SizedBox(height: 6),
                  Container(height: 13, width: 160, decoration: _box),
                  const SizedBox(height: 10),
                  Container(height: 13, width: double.infinity, decoration: _box),
                  const SizedBox(height: 4),
                  Container(height: 13, width: 120, decoration: _box),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(height: 20, width: 56, decoration: _box),
                    const SizedBox(width: 6),
                    Container(height: 20, width: 48, decoration: _box),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration get _box => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      );
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
