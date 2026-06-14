import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_collection.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/collection_service.dart';
import '../remedy/widgets/remedy_card.dart';

const _kGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 380,
  mainAxisExtent: 258,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

class CollectionDetailScreen extends ConsumerWidget {
  final UserCollection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return AppScaffold(
      appBar: WebAppBar(
        title: Text(collection.name),
        actions: [
          if (collection.id != kFavoritesCollectionId)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la collection',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Supprimer la collection ?'),
                  content: const Text('Les remèdes ne seront pas supprimés.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Annuler')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
              if (confirm == true && uid != null && context.mounted) {
                await ref
                    .read(collectionServiceProvider)
                    .delete(uid, collection.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: collection.remedyIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_outline,
                      size: 52, color: AppColors.textTertiary),
                  const SizedBox(height: 14),
                  Text('Collection vide',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Ajoutez des remèdes depuis leur page détail.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _CollectionRemedies(collection: collection, uid: uid),
    );
  }
}

class _CollectionRemedies extends StatelessWidget {
  final UserCollection collection;
  final String? uid;
  const _CollectionRemedies({required this.collection, required this.uid});

  @override
  Widget build(BuildContext context) {
    return _RemedyIdGrid(ids: collection.remedyIds, collectionId: collection.id, uid: uid);
  }
}

class _RemedyIdGrid extends ConsumerWidget {
  final List<String> ids;
  final String collectionId;
  final String? uid;
  const _RemedyIdGrid({required this.ids, required this.collectionId, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(remedyServiceProvider);
    return FutureBuilder(
      future: service.getByIds(ids),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: _kGrid,
            itemCount: ids.length,
            itemBuilder: (_, __) => const RemedyCardSkeleton(),
          );
        }
        final remedies = snap.data ?? [];
        if (remedies.isEmpty) {
          return const Center(child: Text('Aucun remède trouvé.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: _kGrid,
          itemCount: remedies.length,
          itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
        );
      },
    );
  }
}
