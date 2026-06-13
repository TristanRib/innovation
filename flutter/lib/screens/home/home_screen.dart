import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/remedy_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';
import '../../core/constants.dart';

const _kGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 380,
  mainAxisExtent: 258,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Barre de recherche ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Symptôme, remède, ingrédient…',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Effacer la recherche',
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          ),
        ),

        // ── Filtres ─────────────────────────────────────────────────────────
        if (query.isEmpty) ...[
          _TagBar(),
          _SortBar(),
        ],

        // ── Contenu ─────────────────────────────────────────────────────────
        Expanded(
          child: query.isEmpty
              ? NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                      ref.read(remedyFeedProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: const _RemedyGrid(),
                )
              : _SearchResults(query: query),
        ),
      ],
    );
  }
}

// ── Grille principale avec lazy loading ──────────────────────────────────────

class _RemedyGrid extends ConsumerWidget {
  const _RemedyGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(remedyFeedProvider);
    return feedAsync.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        gridDelegate: _kGrid,
        itemCount: 6,
        itemBuilder: (_, __) => const RemedyCardSkeleton(),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (feed) {
        if (feed.items.isEmpty) return const _EmptyState();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => RemedyCard(remedy: feed.items[i]),
                  childCount: feed.items.length,
                ),
                gridDelegate: _kGrid,
              ),
            ),
            if (feed.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            if (!feed.hasMore && feed.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Tous les remèdes sont chargés',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }
}

// ── Résultats de recherche ────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    return resultsAsync.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        gridDelegate: _kGrid,
        itemCount: 4,
        itemBuilder: (_, __) => const RemedyCardSkeleton(),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (results) => results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off,
                          size: 36, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun résultat pour "$query"',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              gridDelegate: _kGrid,
              itemCount: results.length,
              itemBuilder: (_, i) => RemedyCard(remedy: results[i]),
            ),
    );
  }
}

// ── Filtres ───────────────────────────────────────────────────────────────────

class _TagBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTag = ref.watch(selectedTagProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _TagChip(
            label: 'Tous',
            selected: selectedTag == null,
            onTap: () => ref.read(selectedTagProvider.notifier).state = null,
          ),
          ...kAvailableTags.map((tag) => _TagChip(
                label: tag,
                selected: selectedTag == tag,
                onTap: () => ref.read(selectedTagProvider.notifier).state =
                    selectedTag == tag ? null : tag,
              )),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TagChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(sortByProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          DropdownButton<RemediaSortBy>(
            value: sortBy,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textTertiary),
            items: const [
              DropdownMenuItem(value: RemediaSortBy.newest, child: Text('Plus récents')),
              DropdownMenuItem(value: RemediaSortBy.topRated, child: Text('Mieux notés')),
              DropdownMenuItem(
                  value: RemediaSortBy.mostCommented, child: Text('Plus commentés')),
            ],
            onChanged: (v) {
              if (v != null) ref.read(sortByProvider.notifier).state = v;
            },
          ),
        ],
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_outlined, size: 48, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 20),
          Text('Aucun remède pour le moment',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Soyez le premier à en partager un !',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
