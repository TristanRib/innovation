import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/publication.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';

class PublicationsScreen extends ConsumerWidget {
  const PublicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPubs = ref.watch(publicationsProvider);

    return asyncPubs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (pubs) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          if (pubs.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.separated(
                itemCount: pubs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _PublicationCard(pub: pubs[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── En-tête ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apprendre',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Articles & encyclopédie Remedia',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Carte publication ─────────────────────────────────────────────────────────

class _PublicationCard extends StatefulWidget {
  final Publication pub;
  const _PublicationCard({required this.pub});

  @override
  State<_PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<_PublicationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pub = widget.pub;
    final dateStr = DateFormat('d MMM y', 'fr_FR').format(pub.publishedAt);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/publication/${pub.id}', extra: pub),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Color(_hovered ? 0x12000000 : 0x06000000),
                blurRadius: _hovered ? 14 : 6,
                spreadRadius: _hovered ? 1 : 0,
                offset: Offset(0, _hovered ? 4 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image ou placeholder
              _Thumbnail(imageUrl: pub.imageUrl, tags: pub.tags),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pub.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: pub.tags.take(3).map((t) => _TagChip(tag: t)).toList(),
                        ),
                      if (pub.tags.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        pub.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pub.summary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.spa_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            pub.authorName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.schedule_outlined,
                              size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            '${pub.readingTimeMinutes} min',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  final List<String> tags;
  const _Thumbnail({this.imageUrl, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return SizedBox(
        width: 90,
        height: double.infinity,
        child: Image.network(
          imageUrl!,
          width: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderBox(tags: tags),
        ),
      );
    }
    return _PlaceholderBox(tags: tags);
  }
}

class _PlaceholderBox extends StatelessWidget {
  final List<String> tags;
  const _PlaceholderBox({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      constraints: const BoxConstraints(minHeight: 90),
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.article_outlined,
            size: 28, color: AppColors.primaryDark),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined,
                size: 40, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune publication',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'équipe Remedia prépare des articles\nsur les remèdes naturels et la santé.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
