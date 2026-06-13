import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class RemedyCardSkeleton extends StatelessWidget {
  const RemedyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: double.infinity, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 12, width: 200, color: Colors.white),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(height: 24, width: 60, color: Colors.white),
                  const SizedBox(width: 8),
                  Container(height: 24, width: 60, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
