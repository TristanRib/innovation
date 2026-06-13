import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicalDisclaimer extends StatelessWidget {
  const MedicalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.disclaimerBg,
        border: Border.all(color: AppColors.disclaimerBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.disclaimerBorder, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Avertissement : les remèdes présentés ici ne remplacent pas un avis médical. '
              'Consultez un professionnel de santé pour tout problème médical.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE65100),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
