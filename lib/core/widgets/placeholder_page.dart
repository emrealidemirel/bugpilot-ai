import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingLarge),
                Text(title, style: textTheme.headlineMedium),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(description, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
