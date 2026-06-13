import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/remedy.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class RemedyCard extends ConsumerWidget {
  final Remedy remedy;
  const RemedyCard({super.key, required this.remedy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isFavorite = profileAsync.valueOrNull?.favoriteRemedyIds.contains(remedy.id) ?? false;
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/remedy/${remedy.id}', extra: remedy),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      remedy.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (authUser != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () async {
                        await ref.read(remedyServiceProvider).toggleFavorite(
                              authUser.uid,
                              remedy.id,
                              !isFavorite,
                            );
                        ref.invalidate(currentUserProfileProvider);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                remedy.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: remedy.tags
                    .take(3)
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: remedy.averageRating,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    remedy.averageRating > 0
                        ? remedy.averageRating.toStringAsFixed(1)
                        : 'Non noté',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.comment_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${remedy.commentCount}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    remedy.authorName,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
