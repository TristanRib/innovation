import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../models/user_collection.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';

const _kGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 380,
  mainAxisExtent: 258,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicUserProfileProvider(uid));
    return profileAsync.when(
      loading: () => const AppScaffold(body: LoadingOverlay()),
      error: (e, _) => AppScaffold(body: Center(child: Text('$e'))),
      data: (profile) {
        if (profile == null) {
          return const AppScaffold(body: Center(child: Text('Utilisateur introuvable.')));
        }
        return _PublicProfileContent(uid: uid, profile: profile);
      },
    );
  }
}

class _PublicProfileContent extends ConsumerWidget {
  final String uid;
  final UserProfile profile;
  const _PublicProfileContent({required this.uid, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: WebAppBar(title: Text(profile.pseudo)),
      body: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PublicHeader(profile: profile),
            const TabBar(
              tabs: [
                Tab(text: 'Remèdes'),
                Tab(text: 'Collections'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PublicRemediesTab(uid: uid),
                  _PublicCollectionsTab(uid: uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  final UserProfile profile;
  const _PublicHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  profile.pseudo.isNotEmpty ? profile.pseudo[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(profile.pseudo,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (profile.isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.spa, color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text('Premium',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Membre depuis ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(icon: Icons.spa, label: '${profile.createdRemediesCount} remèdes'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PublicRemediesTab extends ConsumerWidget {
  final String uid;
  const _PublicRemediesTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remediesAsync = ref.watch(publicUserRemediesProvider(uid));
    return remediesAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('$e')),
      data: (remedies) => remedies.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.spa_outlined, size: 52, color: AppColors.textTertiary),
                    const SizedBox(height: 14),
                    Text('Aucun remède public.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              gridDelegate: _kGrid,
              itemCount: remedies.length,
              itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
            ),
    );
  }
}

class _PublicCollectionsTab extends ConsumerWidget {
  final String uid;
  const _PublicCollectionsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(publicUserCollectionsProvider(uid));
    return collectionsAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('$e')),
      data: (collections) => collections.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.collections_bookmark_outlined,
                        size: 52, color: AppColors.textTertiary),
                    const SizedBox(height: 14),
                    Text('Aucune collection.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: collections.length,
              itemBuilder: (_, i) => _CollectionCard(collection: collections[i], uid: uid),
            ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final UserCollection collection;
  final String uid;
  const _CollectionCard({required this.collection, required this.uid});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/collection/${collection.id}', extra: collection),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collection.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${collection.remedyIds.length} remède${collection.remedyIds.length > 1 ? 's' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
