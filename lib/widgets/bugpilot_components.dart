import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'package:bugpilot_ai/theme/app_theme.dart';
import 'package:bugpilot_ai/widgets/auth_service_scope.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';

const String bugPilotLogoAsset = 'assets/branding/bugpilot_logo.png';

class BugPilotAppHeader extends StatelessWidget {
  const BugPilotAppHeader({
    this.leading,
    this.trailing,
    this.showBrand = true,
    super.key,
  });

  final Widget? leading;
  final Widget? trailing;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLarge),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BugPilotAvatar(size: 32),
                  if (leading != null) ...[
                    const SizedBox(width: AppDimensions.spacingSmall),
                    leading!,
                  ],
                ],
              ),
            ),
            if (showBrand) const Center(child: BugPilotLogoMark(size: 36)),
            if (trailing != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

class BugPilotRootHeader extends StatelessWidget {
  const BugPilotRootHeader({super.key});

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
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BugPilotAvatar(size: 32),
                  ),
                  Center(child: BugPilotLogoMark(size: 36)),
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
    final authScope = AuthServiceScope.maybeOf(context);
    final user = authScope?.user;
    final photoUrl = user?.photoUrl;
    final localPhoto = user?.localPhotoBytes;
    final ImageProvider<Object>? photo = localPhoto != null
        ? MemoryImage(localPhoto)
        : photoUrl != null && photoUrl.isNotEmpty
        ? NetworkImage(photoUrl)
        : null;
    return Semantics(
      label: 'accountMenu'.tr(),
      button: true,
      child: Tooltip(
        message: 'accountMenu'.tr(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.hasDrawer) {
              scaffold.openDrawer();
            } else {
              context.push('/profile');
            }
          },
          child: CircleAvatar(
            radius: size / 2,
            backgroundImage: photo,
            child: photo == null
                ? const Icon(Icons.person_outline_rounded)
                : null,
          ),
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
