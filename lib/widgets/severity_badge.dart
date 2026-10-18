import 'package:flutter/material.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({required this.severity, super.key});

  final BugSeverity? severity;

  @override
  Widget build(BuildContext context) {
    final label = severity == null
        ? context.l10n.severityUnassigned
        : context.l10n.bugSeverityLabel(severity!);
    final colors = _colorsFor(context, severity);

    return _Badge(
      label: label,
      backgroundColor: colors.background,
      textColor: colors.text,
    );
  }

  _BadgeColors _colorsFor(BuildContext context, BugSeverity? severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _BadgeColors(
        background: Color(0xFF3B2426),
        text: Color(0xFFFFB4AB),
      );
    }

    return switch (severity) {
      BugSeverity.critical || BugSeverity.high => const _BadgeColors(
        background: Color(0x80FFDAD6),
        text: AppTheme.onErrorContainer,
      ),
      BugSeverity.medium || BugSeverity.low || null => const _BadgeColors(
        background: AppTheme.surfaceContainer,
        text: AppTheme.textSecondary,
      ),
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSmall,
            vertical: AppDimensions.spacingXSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontFamily: AppTheme.uiFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeColors {
  const _BadgeColors({required this.background, required this.text});

  final Color background;
  final Color text;
}
