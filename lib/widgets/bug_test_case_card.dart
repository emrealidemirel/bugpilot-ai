import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';

class BugTestCaseCard extends StatelessWidget {
  const BugTestCaseCard({required this.testCase, super.key});

  final BugTestCase testCase;

  @override
  Widget build(BuildContext context) {
    final type = testCase.type;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.mutedSurfaceFor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppDimensions.spacingSmall,
              runSpacing: AppDimensions.spacingSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MiniBadge(label: testCase.id),
                if (type != null)
                  _MiniBadge(label: context.l10n.localizedTestCaseType(type)),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              testCase.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _GivenWhenThen(label: 'givenLabel'.tr(), text: testCase.given),
            _GivenWhenThen(label: 'whenLabel'.tr(), text: testCase.when),
            _GivenWhenThen(label: 'thenLabel'.tr(), text: testCase.then),
          ],
        ),
      ),
    );
  }
}

class _GivenWhenThen extends StatelessWidget {
  const _GivenWhenThen({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXSmall),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingXSmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimaryFor(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
