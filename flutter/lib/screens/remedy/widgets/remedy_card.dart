import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/remedy.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class RemedyCard extends ConsumerWidget {
  final Remedy remedy;
  const RemedyCard({super.key, required this.remedy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      currentUserProfileProvider.select(
        (p) => p.valueOrNull?.favoriteRemedyIds.contains(remedy.id) ?? false,
      ),
    );
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Semantics(
      label: '${remedy.title}. ${remedy.description}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => context.push('/remedy/${remedy.id}', extra: remedy),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image / placeholder avec badges superposés
                Stack(
                  children: [
                    if (remedy.imageUrl != null)
                      Image.network(
                        remedy.imageUrl!,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: remedy.title,
                        errorBuilder: (_, __, ___) => _Placeholder(),
                      )
                    else
                      _Placeholder(),
                    if (remedy.authorIsPremium)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.spa, color: Colors.white, size: 12),
                        ),
                      ),
                    if (remedy.isPrivate)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Privé',
                                  style: TextStyle(fontSize: 9, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        remedy.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remedy.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (remedy.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: remedy.tags.take(2).map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )).toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (remedy.averageRating > 0) ...[
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              remedy.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${remedy.commentCount}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          if (authUser != null)
                            Semantics(
                              label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                              button: true,
                              child: IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_outline,
                                  size: 18,
                                  color: isFavorite ? AppColors.error : AppColors.textSecondary,
                                ),
                                onPressed: () async {
                                  await ref.read(remedyServiceProvider).toggleFavorite(
                                        authUser.uid,
                                        remedy.id,
                                        !isFavorite,
                                      );
                                  ref.invalidate(currentUserProfileProvider);
                                },
                                tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      color: AppColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.spa_outlined,
          size: 32,
          color: AppColors.primaryDark.withOpacity(0.4),
        ),
      ),
    );
  }
}
