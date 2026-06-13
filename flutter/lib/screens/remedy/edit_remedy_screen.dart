import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/remedy.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';
import '../../core/constants.dart';

class EditRemedyScreen extends ConsumerStatefulWidget {
  final Remedy remedy;
  const EditRemedyScreen({super.key, required this.remedy});

  @override
  ConsumerState<EditRemedyScreen> createState() => _EditRemedyScreenState();
}

class _EditRemedyScreenState extends ConsumerState<EditRemedyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _methodCtrl;
  final TextEditingController _ingredientCtrl = TextEditingController();

  late List<String> _ingredients;
  late Set<String> _selectedTags;
  late bool _isPrivate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.remedy;
    _titleCtrl = TextEditingController(text: r.title);
    _descCtrl = TextEditingController(text: r.description);
    _methodCtrl = TextEditingController(text: r.method);
    _ingredients = List<String>.from(r.ingredients);
    _selectedTags = Set<String>.from(r.tags);
    _isPrivate = r.isPrivate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _methodCtrl.dispose();
    _ingredientCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final v = _ingredientCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _ingredients.add(v);
      _ingredientCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un ingrédient.')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une catégorie.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final updated = Remedy(
        id: widget.remedy.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        ingredients: _ingredients,
        method: _methodCtrl.text.trim(),
        tags: _selectedTags.toList(),
        authorId: widget.remedy.authorId,
        authorName: widget.remedy.authorName,
        createdAt: widget.remedy.createdAt,
        averageRating: widget.remedy.averageRating,
        ratingCount: widget.remedy.ratingCount,
        commentCount: widget.remedy.commentCount,
        imageUrl: widget.remedy.imageUrl,
        isReported: widget.remedy.isReported,
        isPrivate: _isPrivate,
        authorIsPremium: widget.remedy.authorIsPremium,
      );

      await ref.read(remedyServiceProvider).updateRemedy(updated);

      ref.invalidate(remedyByIdProvider(updated.id));
      ref.invalidate(userRemediesProvider);
      ref.invalidate(remedyFeedProvider);

      // Re-analyse en arrière-plan avec les nouvelles données
      // ignore: unawaited_futures
      ref.read(groqServiceProvider).analyzeRemedy(updated, forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remède mis à jour !')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        ref.watch(currentUserProfileProvider).valueOrNull?.isPremium ?? false;

    return AppScaffold(
      appBar: const WebAppBar(title: Text('Modifier le remède')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du remède *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Pour quel symptôme ? Quel est l\'effet attendu ?',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),

            Text('Ingrédients *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ingredientCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Miel, citron, gingembre…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onFieldSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _ingredients
                    .map((ing) => Chip(
                          label: Text(ing),
                          onDeleted: () => setState(() => _ingredients.remove(ing)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            TextFormField(
              controller: _methodCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Préparation *',
                hintText: 'Décrivez étape par étape comment préparer ce remède.',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),

            Text('Catégories *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: kAvailableTags
                  .map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        }),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedTags.contains(tag)
                              ? Colors.white
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            if (isPremium)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  title: const Text('Remède privé'),
                  subtitle: const Text('Visible uniquement par vous'),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: AppColors.primaryDark, size: 20),
                  ),
                  activeColor: AppColors.primary,
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Enregistrer les modifications'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
