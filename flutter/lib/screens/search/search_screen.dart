import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Symptôme, remède, ingrédient…',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            filled: false,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _ctrl.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        ),
      ),
      body: query.trim().isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 64, color: AppColors.primaryLight),
                  const SizedBox(height: 12),
                  Text(
                    'Recherchez par symptôme\nou nom de remède',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : resultsAsync.when(
              loading: () => ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => const RemedyCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (results) => results.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun résultat pour "$query"',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: results.length,
                      itemBuilder: (_, i) => RemedyCard(remedy: results[i]),
                    ),
            ),
    );
  }
}
