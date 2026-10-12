import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/enums/bug_test_case_type.dart';
import '../../domain/models/bug_test_case.dart';

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
                if (type != null) _MiniBadge(label: type.label),
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
            _GivenWhenThen(label: 'Given', text: testCase.given),
            _GivenWhenThen(label: 'When', text: testCase.when),
            _GivenWhenThen(label: 'Then', text: testCase.then),
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
