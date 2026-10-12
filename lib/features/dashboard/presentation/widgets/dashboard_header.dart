import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Good afternoon,',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryFor(context),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXSmall),
        Text(
          "let's squash some bugs.",
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}
