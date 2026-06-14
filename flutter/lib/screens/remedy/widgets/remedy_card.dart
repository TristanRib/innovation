import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/remedy.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/collection_service.dart';

class RemedyCard extends ConsumerStatefulWidget {
  final Remedy remedy;
  const RemedyCard({super.key, required this.remedy});

  @override
  ConsumerState<RemedyCard> createState() => _RemedyCardState();
}

class _RemedyCardState extends ConsumerState<RemedyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final remedy = widget.remedy;
    final collections = ref.watch(userCollectionsProvider).valueOrNull ?? [];
    final isFavorite = collections
        .where((c) => c.id == kFavoritesCollectionId)
        .any((c) => c.remedyIds.contains(remedy.id));
    final authUser = ref.watch(authStateProvider).valueOrNull;

    final isPremium = remedy.authorIsPremium;
    final collectionCount = ref
            .watch(userCollectionsProvider)
            .valueOrNull
            ?.where((c) => c.remedyIds.contains(remedy.id))
            .length ??
        0;

    return Semantics(
      label: '${remedy.title}. ${remedy.description}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: () => context.push('/remedy/${remedy.id}', extra: remedy),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isPremium ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isPremium ? null : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: isPremium
                      ? AppColors.primary.withOpacity(_hovered ? 0.4 : 0.25)
                      : Color(_hovered ? 0x14000000 : 0x08000000),
                  blurRadius: isPremium ? (_hovered ? 20 : 12) : (_hovered ? 14 : 8),
                  spreadRadius: _hovered ? 1 : 0,
                  offset: Offset(0, _hovered ? 5 : 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    if (remedy.imageUrl != null)
                      Image.network(
                        remedy.imageUrl!,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: remedy.title,
                        errorBuilder: (_, __, ___) => _Placeholder(isPremium: isPremium),
                      )
                    else
                      _Placeholder(isPremium: isPremium),
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
                    if (authUser != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Semantics(
                          label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                          button: true,
                          child: Material(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                await ref.read(collectionServiceProvider).toggleFavorite(
                                      authUser.uid, remedy.id, !isFavorite);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline,
                                  size: 16,
                                  color: isFavorite
                                      ? const Color(0xFFFF6B6B)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        remedy.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isPremium ? Colors.white : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remedy.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPremium
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (remedy.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: remedy.tags.take(2).map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPremium
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isPremium
                                        ? Colors.white
                                        : AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )).toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (remedy.averageRating > 0) ...[
                            const Icon(Icons.star_rounded,
                                size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              remedy.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPremium
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 12,
                              color: isPremium
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${remedy.commentCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPremium
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (collectionCount > 0) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.bookmark_rounded,
                                size: 12,
                                color: isPremium
                                    ? Colors.white70
                                    : AppColors.primaryDark),
                            if (collectionCount > 1) ...[
                              const SizedBox(width: 2),
                              Text(
                                '$collectionCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPremium
                                      ? Colors.white70
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ],
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
  final bool isPremium;
  const _Placeholder({this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      color: isPremium ? AppColors.primaryDark : AppColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.spa_outlined,
          size: 32,
          color: isPremium
              ? Colors.white.withOpacity(0.3)
              : AppColors.primaryDark.withOpacity(0.4),
        ),
      ),
    );
  }
}
