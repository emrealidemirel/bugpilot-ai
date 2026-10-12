import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../constants/app_dimensions.dart';

const String bugPilotLogoAsset = 'assets/branding/bugpilot_logo.png';
const String bugPilotAvatarAsset = 'assets/images/profile_avatar.png';

String bugDisplayId(String id) {
  final digits = RegExp(r'\d+').allMatches(id).map((match) => match.group(0)!);
  final numeric = digits.isEmpty
      ? _stableNumericId(id).toString()
      : digits.join();
  final compact = numeric.length <= 3
      ? numeric.padLeft(3, '0')
      : numeric.substring(numeric.length - 3);
  return '#$compact';
}

int _stableNumericId(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash % 1000;
}

class BugPilotAppHeader extends StatelessWidget {
  const BugPilotAppHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showBrand = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLarge),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppDimensions.spacingSmall),
          ] else if (showBrand) ...[
            const BugPilotLogoMark(size: 34),
            const SizedBox(width: AppDimensions.spacingSmall),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spacingXSmall),
                  Text(subtitle!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          trailing ?? const BugPilotAvatar(),
        ],
      ),
    );
  }
}

class BugPilotRootHeader extends StatelessWidget {
  const BugPilotRootHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkBackground
        : AppTheme.background;

    return Semantics(
      container: true,
      header: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor.withAlpha(230),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: SizedBox(
            height: AppDimensions.rootHeaderVisualHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding,
              ),
              child: Row(
                children: [
                  const BugPilotLogoMark(size: 24),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppTheme.textPrimaryFor(context)),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  const BugPilotAvatar(size: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BugPilotLogoMark extends StatelessWidget {
  const BugPilotLogoMark({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      bugPilotLogoAsset,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'BugPilot AI Logo',
    );
  }
}

class BugPilotAvatar extends StatelessWidget {
  const BugPilotAvatar({this.size = 34, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile avatar',
      image: true,
      child: ClipOval(
        child: Image.asset(
          bugPilotAvatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class BugPilotCard extends StatelessWidget {
  const BugPilotCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingLarge),
    this.color,
    this.borderColor,
    this.onTap,
    this.semanticAccent,
    this.radius,
    this.shadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? semanticAccent;
  final double? radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(
      radius ?? AppDimensions.radiusLarge,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: borderColor ?? colorScheme.outlineVariant),
    );
    final content = Stack(
      children: [
        if (semanticAccent != null)
          Positioned.fill(
            left: 0,
            right: null,
            child: ColoredBox(
              color: semanticAccent!,
              child: const SizedBox(width: 3),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? colorScheme.surface,
        shape: shape,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class BugPilotFieldLabel extends StatelessWidget {
  const BugPilotFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.textSecondaryFor(context),
        ),
      ),
    );
  }
}

class BugPilotTechnicalBox extends StatelessWidget {
  const BugPilotTechnicalBox({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.technicalDarkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: const Color(0xFF253044)),
      ),
      child: child,
    );
  }
}

class BugPilotSectionTitle extends StatelessWidget {
  const BugPilotSectionTitle({
    required this.title,
    this.action,
    this.icon,
    super.key,
  });

  final String title;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppDimensions.spacingSmall),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}
