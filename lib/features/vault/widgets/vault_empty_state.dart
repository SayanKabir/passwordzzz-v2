import 'package:flutter/material.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';

class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.brandMuted,
                borderRadius: BorderRadius.circular(Radii.xl),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 40,
                color: c.brand,
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(
              'Your vault is empty',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Passwords you save will appear here, '
              'encrypted on this device.',
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
