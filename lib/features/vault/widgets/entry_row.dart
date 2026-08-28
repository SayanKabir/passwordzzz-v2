import 'package:flutter/material.dart';

import '../../../data/models/vault_entry.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';

/// One vault row. Fixed height so the list can use `itemExtent`.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    // RepaintBoundary per row: without it, a ripple on one row repaints the
    // whole visible list.
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: kVaultRowExtent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(
              children: [
                _Avatar(entry: entry),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      if (entry.username.isNotEmpty)
                        Text(
                          entry.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: c.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Letter avatar with a hue derived from the site name.
///
/// Favicons are deliberately absent for now: v1 fetched them from Google's
/// endpoint on every render, which sent the user's entire site list to Google.
/// Phase 7 replaces that with a proxied, cached fetch.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hue = (entry.site.hashCode.abs() % 360).toDouble();
    final tint = HSLColor.fromAHSL(1, hue, 0.32, 0.55).toColor();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.28),
            tint.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: c.border),
      ),
      alignment: Alignment.center,
      child: Text(
        entry.initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
