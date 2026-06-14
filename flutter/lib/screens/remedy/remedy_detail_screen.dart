import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/remedy.dart';
import '../../models/comment.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medical_disclaimer.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';
import '../../services/pdf_service.dart';
import 'widgets/ai_analysis_widget.dart';

class RemedyDetailScreen extends ConsumerStatefulWidget {
  final Remedy remedy;
  const RemedyDetailScreen({super.key, required this.remedy});

  @override
  ConsumerState<RemedyDetailScreen> createState() => _RemedyDetailScreenState();
}

class _RemedyDetailScreenState extends ConsumerState<RemedyDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submittingComment = false;
  bool _submittingRating = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push('/login');
      return;
    }
    final profile = await ref.read(currentUserProfileProvider.future);
    setState(() => _submittingComment = true);
    try {
      await ref.read(commentServiceProvider).addComment(
            remedyId: widget.remedy.id,
            authorId: user.uid,
            authorName: profile?.pseudo ?? 'Anonyme',
            content: content,
          );
      _commentCtrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer le commentaire.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _rate(double stars) async {
    if (_submittingRating) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push('/login');
      return;
    }
    setState(() => _submittingRating = true);
    try {
      await ref.read(remedyServiceProvider).rateRemedy(
            widget.remedy.id,
            user.uid,
            stars.round(),
          );
      ref.invalidate(userRatingProvider(widget.remedy.id));
      ref.invalidate(remedyByIdProvider(widget.remedy.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'enregistrer la note.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingRating = false);
    }
  }

  void _showAddToCollectionSheet(BuildContext context, String remedyId) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddToCollectionSheet(uid: uid, remedyId: remedyId),
    );
  }

  void _showReportDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Signaler ce remède'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Motif du signalement'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user != null) {
                await ref.read(remedyServiceProvider).reportRemedy(
                      widget.remedy.id,
                      user.uid,
                      reasonCtrl.text,
                    );
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement envoyé, merci.')),
                );
              }
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    ).then((_) => reasonCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(remedyByIdProvider(widget.remedy.id)).valueOrNull ?? widget.remedy;
    final commentsAsync = ref.watch(commentsProvider(r.id));
    final userRatingAsync = ref.watch(userRatingProvider(r.id));
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isPremium =
        ref.watch(currentUserProfileProvider).valueOrNull?.isPremium ?? false;

    final isWide = MediaQuery.of(context).size.width >= 600;

    return AppScaffold(
      appBar: WebAppBar(
        title: Text(r.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (authUser != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Ajouter à une collection',
              onPressed: () => _showAddToCollectionSheet(context, r.id),
            ),
          if (isPremium)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exporter en PDF',
              onPressed: () => PdfService().exportRemedy(r),
            ),
          if (authUser != null && authUser.uid == r.authorId)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => context.push('/edit-remedy', extra: r),
            ),
          if (authUser != null && authUser.uid != r.authorId)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Signaler',
              onPressed: _showReportDialog,
            ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (r.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(r.imageUrl!, height: 200, fit: BoxFit.cover),
            ),
          if (r.imageUrl != null) const SizedBox(height: 16),

          // Disclaimer
          const MedicalDisclaimer(),
          const SizedBox(height: 16),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: r.tags.map((t) => Chip(label: Text(t))).toList(),
          ),
          const SizedBox(height: 16),

          // Description + Ingrédients (50/50 si large)
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DescriptionBlock(remedy: r)),
                  const SizedBox(width: 16),
                  Expanded(child: _IngredientsBlock(remedy: r)),
                ],
              ),
            )
          else ...[
            _DescriptionBlock(remedy: r),
            const SizedBox(height: 20),
            _IngredientsBlock(remedy: r),
          ],
          const SizedBox(height: 20),

          // Method
          Text('Préparation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(r.method, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 20),

          // Analyse IA
          AiAnalysisWidget(remedy: r),
          const SizedBox(height: 12),

          // Collections contenant ce remède
          if (authUser != null) _CollectionMemberships(remedyId: r.id),
          if (authUser != null) const SizedBox(height: 20),

          // Rating (50/50 si large)
          _RatingSection(
            remedy: r,
            userRatingAsync: userRatingAsync,
            onRate: _rate,
            isWide: isWide,
          ),
          const Divider(height: 32),

          // Meta
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => authUser?.uid == r.authorId
                      ? context.go('/profile')
                      : context.push('/user/${r.authorId}'),
                  child: Text(r.authorName,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          )),
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(r.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Divider(height: 32),

          // Comments
          Text('Commentaires', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          if (authUser != null) _CommentInput(ctrl: _commentCtrl, submitting: _submittingComment, onSubmit: _submitComment),
          if (authUser != null) const SizedBox(height: 12),

          commentsAsync.when(
            loading: () => const LoadingOverlay(),
            error: (e, _) => Text('Erreur : $e'),
            data: (comments) => comments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Aucun commentaire. Soyez le premier !',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    children: comments.map((c) => _CommentTile(comment: c)).toList(),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  final Remedy remedy;
  const _DescriptionBlock({required this.remedy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(remedy.description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _IngredientsBlock extends StatelessWidget {
  final Remedy remedy;
  const _IngredientsBlock({required this.remedy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingrédients', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...remedy.ingredients.map(
          (ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.fiber_manual_record, size: 8, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(ing, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionMemberships extends ConsumerWidget {
  final String remedyId;
  const _CollectionMemberships({required this.remedyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref
            .watch(userCollectionsProvider)
            .valueOrNull
            ?.where((c) => c.remedyIds.contains(remedyId))
            .toList() ??
        [];
    if (collections.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        const Icon(Icons.bookmark_rounded, size: 14, color: AppColors.primaryDark),
        ...collections.map(
          (c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              c.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddToCollectionSheet extends ConsumerWidget {
  final String uid;
  final String remedyId;
  const _AddToCollectionSheet({required this.uid, required this.remedyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(userCollectionsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Ajouter à une collection',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(),
          collectionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur : $e'),
            ),
            data: (collections) => collections.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Aucune collection — créez-en une ci-dessous.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: collections.length,
                    itemBuilder: (_, i) {
                      final col = collections[i];
                      final contains = col.remedyIds.contains(remedyId);
                      return CheckboxListTile(
                        value: contains,
                        title: Text(col.name),
                        subtitle: Text('${col.remedyIds.length} remède(s)'),
                        activeColor: AppColors.primary,
                        onChanged: (_) async {
                          final svc = ref.read(collectionServiceProvider);
                          if (contains) {
                            await svc.removeRemedy(uid, col.id, remedyId);
                          } else {
                            await svc.addRemedy(uid, col.id, remedyId);
                          }
                        },
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
            title: const Text('Nouvelle collection'),
            onTap: () async {
              final ctrl = TextEditingController();
              final created = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Nouvelle collection'),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration:
                        const InputDecoration(hintText: 'Nom de la collection'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (ctrl.text.trim().isEmpty) return;
                        final col = await ref
                            .read(collectionServiceProvider)
                            .create(uid, ctrl.text.trim());
                        await ref
                            .read(collectionServiceProvider)
                            .addRemedy(uid, col.id, remedyId);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                      },
                      child: const Text('Créer'),
                    ),
                  ],
                ),
              );
              ctrl.dispose();
              if (created == true && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  final Remedy remedy;
  final AsyncValue<int?> userRatingAsync;
  final void Function(double) onRate;
  final bool isWide;

  const _RatingSection({
    required this.remedy,
    required this.userRatingAsync,
    required this.onRate,
    this.isWide = false,
  });

  Widget _averageBlock(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note moyenne', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: remedy.averageRating,
            itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            itemCount: 5,
            itemSize: 24,
          ),
          const SizedBox(height: 4),
          Text(
            remedy.averageRating > 0
                ? '${remedy.averageRating.toStringAsFixed(1)} / 5 (${remedy.ratingCount} votes)'
                : 'Non noté',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );

  Widget _userBlock(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre note', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          userRatingAsync.when(
            loading: () => const SizedBox(height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox(),
            data: (userRating) => RatingBar.builder(
              initialRating: userRating?.toDouble() ?? 0,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: onRate,
              itemSize: 32,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _averageBlock(context)),
          const SizedBox(width: 16),
          Expanded(child: _userBlock(context)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _averageBlock(context),
        const SizedBox(height: 16),
        _userBlock(context),
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool submitting;
  final VoidCallback onSubmit;

  const _CommentInput({required this.ctrl, required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Ajouter un commentaire…',
              labelText: 'Commentaire',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isOwn = authUser?.uid == comment.authorId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy').format(comment.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    if (isOwn) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        tooltip: 'Supprimer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Supprimer le commentaire ?'),
                              content: const Text('Cette action est irréversible.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(commentServiceProvider)
                                .deleteComment(comment.remedyId, comment.id);
                          }
                        },
                      ),
                    ] else if (authUser != null) ...[
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.textSecondary),
                        tooltip: 'Signaler',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () async {
                          await ref
                              .read(commentServiceProvider)
                              .reportComment(comment.remedyId, comment.id, authUser.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Commentaire signalé.')),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

