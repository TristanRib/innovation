import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/remedy_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';

const _tags = [
  'Rhume', 'Digestion', 'Sommeil', 'Énergie', 'Peau', 'Maux de tête',
  'Gorge', 'Stress', 'Allergie', 'Articulations',
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remediesAsync = ref.watch(remediesProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final sortBy = ref.watch(sortByProvider);
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remedia'),
        leading: const Icon(Icons.spa),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          authAsync.valueOrNull != null
              ? IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push('/profile'),
                )
              : TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Connexion', style: TextStyle(color: Colors.white)),
                ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagBar(selectedTag: selectedTag),
          _SortBar(sortBy: sortBy),
          Expanded(
            child: remediesAsync.when(
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const RemedyCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (remedies) => remedies.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: remedies.length,
                      itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: authAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add),
              label: const Text('Partager un remède'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}

class _TagBar extends ConsumerWidget {
  final String? selectedTag;
  const _TagBar({required this.selectedTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tous'),
              selected: selectedTag == null,
              onSelected: (_) => ref.read(selectedTagProvider.notifier).state = null,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selectedTag == null ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._tags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag),
                  selected: selectedTag == tag,
                  onSelected: (_) =>
                      ref.read(selectedTagProvider.notifier).state =
                          selectedTag == tag ? null : tag,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selectedTag == tag ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SortBar extends ConsumerWidget {
  final RemediaSortBy sortBy;
  const _SortBar({required this.sortBy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('Trier par :', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          DropdownButton<RemediaSortBy>(
            value: sortBy,
            underline: const SizedBox(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
            items: const [
              DropdownMenuItem(value: RemediaSortBy.newest, child: Text('Plus récents')),
              DropdownMenuItem(value: RemediaSortBy.topRated, child: Text('Mieux notés')),
              DropdownMenuItem(value: RemediaSortBy.mostCommented, child: Text('Plus commentés')),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa_outlined, size: 64, color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Text(
            'Aucun remède pour le moment.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager !',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
