import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'dashboardGreeting'.tr(),
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryFor(context),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXSmall),
        Text(
          'dashboardGreetingMessage'.tr(),
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}
