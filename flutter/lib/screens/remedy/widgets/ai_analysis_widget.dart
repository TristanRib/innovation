import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/remedy.dart';
import '../../../models/ai_analysis.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class AiAnalysisWidget extends ConsumerStatefulWidget {
  final Remedy remedy;
  const AiAnalysisWidget({super.key, required this.remedy});

  @override
  ConsumerState<AiAnalysisWidget> createState() => _AiAnalysisWidgetState();
}

class _AiAnalysisWidgetState extends ConsumerState<AiAnalysisWidget> {
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isPremium = profileAsync.valueOrNull?.isPremium ?? false;

    if (!isPremium) return const _PremiumLockedCard();

    final analysisAsync = ref.watch(remedyAnalysisProvider(widget.remedy.id));
    return analysisAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (analysis) {
        if (analysis == null && !_triggered) {
          _triggered = true;
          Future.microtask(() {
            // ignore: unawaited_futures
            ref.read(groqServiceProvider).analyzeRemedy(widget.remedy);
          });
        }
        return analysis == null ? const SizedBox.shrink() : _AnalysisCard(analysis: analysis);
      },
    );
  }
}

// ── Carte premium verrouillée ─────────────────────────────────────────────────

class _PremiumLockedCard extends StatelessWidget {
  const _PremiumLockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse IA — Membres Premium',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passez en Premium pour accéder à l\'analyse scientifique, aux effets documentés et aux contre-indications.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte de résultat ─────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final AiAnalysis analysis;
  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'Analyse IA',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                _InlineRow(
                  icon: Icons.science_outlined,
                  iconColor: analysis.evidenceColor,
                  title: 'Preuves',
                  value: analysis.evidenceLevel,
                ),
                const SizedBox(width: 16),
                _InlineRow(
                  icon: Icons.shield_outlined,
                  iconColor: analysis.safetyColor,
                  title: 'Sécurité',
                  value: '${analysis.safetyScore}/5',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé
                Text(analysis.summary, style: Theme.of(context).textTheme.bodyMedium),

                if (analysis.provenBenefits.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.primary,
                    title: 'Effets documentés',
                    items: analysis.provenBenefits,
                  ),
                ],

                if (analysis.contraindications.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppColors.warning,
                    title: 'Contre-indications',
                    items: analysis.contraindications,
                  ),
                ],

                if (analysis.drugInteractions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon: Icons.medication_outlined,
                    iconColor: const Color(0xFFD32F2F),
                    title: 'Interactions médicamenteuses',
                    items: analysis.drugInteractions,
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  const _InlineRow({required this.icon, required this.iconColor, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Icon(icon, size: 14, color: iconColor),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            children: [
              TextSpan(
                text: '$title : ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fiber_manual_record, size: 7, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
