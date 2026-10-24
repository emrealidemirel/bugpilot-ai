import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/constants/app_dimensions.dart';
import 'package:bugpilot_ai/widgets/bugpilot_components.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/widgets/auth_service_scope.dart';
import 'package:bugpilot_ai/widgets/account_management_panel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({this.isDrawer = false, super.key});

  static const routePath = '/profile';
  final bool isDrawer;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoContentType;
  bool _busy = false;
  bool _isEditing = false;
  bool _syncingProfileFields = false;
  bool _profileFieldsEdited = false;
  String? _loadedProfileIdentity;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController()
      ..addListener(_markProfileEdited);
    _lastNameController = TextEditingController()
      ..addListener(_markProfileEdited);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AuthServiceScope.maybeOf(context);
    _syncProfileFields(scope?.service?.currentUser ?? scope?.user);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_markProfileEdited);
    _lastNameController.removeListener(_markProfileEdited);
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _markProfileEdited() {
    if (!_syncingProfileFields) _profileFieldsEdited = true;
  }

  void _syncProfileFields(AuthUser? user) {
    if (user == null || _profileFieldsEdited) return;
    final identity = '${user.id}:${user.displayName}:${user.email}';
    if (identity == _loadedProfileIdentity) return;

    final parts = _profileNameParts(user);
    _syncingProfileFields = true;
    _firstNameController.text = parts.isEmpty ? '' : parts.first;
    _lastNameController.text = parts.length < 2 ? '' : parts.skip(1).join(' ');
    _syncingProfileFields = false;
    _loadedProfileIdentity = identity;
  }

  List<String> _profileNameParts(AuthUser user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+'));
    }

    // Email/password accounts do not provide a separate name field. Use a
    // recognizable email prefix as an editable fallback when no profile name
    // was saved during registration.
    final localPart = user.email.split('@').first.split('+').first;
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map(_capitalize)
        .toList(growable: false);
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final scope = AuthServiceScope.maybeOf(context);
    final user = scope?.user;
    final theme = Theme.of(context);

    final profileContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.spacingMedium,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton.filledTonal(
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          tooltip: widget.isDrawer
                              ? 'closeAction'.tr()
                              : 'backAction'.tr(),
                          onPressed: () => widget.isDrawer
                              ? Navigator.of(context).pop()
                              : context.pop(),
                          icon: Icon(
                            widget.isDrawer
                                ? Icons.close_rounded
                                : Icons.arrow_back_rounded,
                          ),
                        ),
                      ),
                      const Center(child: BugPilotLogoMark(size: 36)),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                Text(
                  'profileTitle'.tr(),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppDimensions.spacingXSmall),
                Text(
                  'profileDescription'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXLarge),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.09),
                        theme.colorScheme.primary.withValues(alpha: 0.025),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _profilePhoto(user)),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      // Both views share their measured height so actions never jump
                      // when switching modes, including with larger text settings.
                      IndexedStack(
                        index: _isEditing ? 1 : 0,
                        alignment: Alignment.center,
                        children: [
                          _profileDetailsCard(user),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        enabled: !_busy,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        autofillHints: const [
                                          AutofillHints.givenName,
                                        ],
                                        decoration: _profileInputDecoration(
                                          labelText: 'firstNameLabel'.tr(),
                                        ),
                                        validator: _validateName,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppDimensions.spacingMedium,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        enabled: !_busy,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        autofillHints: const [
                                          AutofillHints.familyName,
                                        ],
                                        decoration: _profileInputDecoration(
                                          labelText: 'lastNameLabel'.tr(),
                                        ),
                                        validator: _validateName,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: AppDimensions.spacingMedium,
                                ),
                                TextFormField(
                                  initialValue: user?.email ?? '',
                                  readOnly: true,
                                  decoration: _profileInputDecoration(
                                    labelText: context.l10n.emailLabel,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXLarge),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: user == null || _busy
                      ? null
                      : _isEditing
                      ? _saveProfile
                      : () => setState(() => _isEditing = true),
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        ),
                  label: Text(
                    _busy
                        ? context.l10n.pleaseWait
                        : (_isEditing ? 'saveProfile' : 'editProfile').tr(),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                if (_isEditing)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: user == null || _busy ? null : _cancelEditing,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        foregroundColor: theme.colorScheme.error,
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text('cancelProfileEditing'.tr()),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      iconSize: 19,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: user == null || _busy
                        ? null
                        : () => AuthServiceScope.of(context)?.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(context.l10n.signOut),
                  ),
                const SizedBox(height: AppDimensions.spacingMedium),
                Visibility(
                  visible: !_isEditing,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      iconSize: 19,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busy
                        ? null
                        : () => showAccountManagementSheet(context),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text('accountAndData'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isDrawer) return profileContent;
    return Scaffold(body: profileContent);
  }

  void _cancelEditing() {
    _formKey.currentState?.reset();
    FocusScope.of(context).unfocus();
    setState(() {
      _isEditing = false;
      _selectedPhotoBytes = null;
      _selectedPhotoContentType = null;
      _profileFieldsEdited = false;
      _loadedProfileIdentity = null;
      final scope = AuthServiceScope.maybeOf(context);
      _syncProfileFields(scope?.service?.currentUser ?? scope?.user);
    });
  }

  Widget _profileDetailsCard(AuthUser? user) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fullName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final nameColor = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.65),
      colors.onSurface,
    );

    return Padding(
      key: const ValueKey('profile-details-card'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            fullName.isEmpty ? '—' : fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: nameColor,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user?.email ?? '—',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          TextButton.icon(
            onPressed: _busy ? null : _choosePhotoSource,
            style: TextButton.styleFrom(
              textStyle: theme.textTheme.labelMedium,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: Text('changeProfilePhoto'.tr()),
          ),
        ],
      ),
    );
  }

  InputDecoration _profileInputDecoration({
    required String labelText,
    Widget? prefixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      prefixIconColor: colors.primary,
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }

  Widget _profilePhoto(AuthUser? user) {
    final photoUrl = user?.photoUrl;
    final imageBytes = _selectedPhotoBytes ?? user?.localPhotoBytes;
    final ImageProvider<Object>? image;
    if (imageBytes != null) {
      image = MemoryImage(imageBytes);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      image = NetworkImage(photoUrl);
    } else {
      image = null;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: image,
        child: image == null
            ? Icon(
                Icons.person_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }

  String? _validateName(String? value) =>
      value == null || value.trim().isEmpty ? 'profileNameRequired'.tr() : null;

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('takePhoto'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('chooseFromGallery'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = bytes;
        final mimeType = image.mimeType;
        _selectedPhotoContentType =
            mimeType != null && mimeType.toLowerCase().startsWith('image/')
            ? mimeType.toLowerCase()
            : _contentType(image.name);
      });
      await _saveProfile(photoOnly: true);
    } catch (_) {
      if (mounted) _showMessage('profilePhotoPickError'.tr(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _selectedPhotoBytes = null;
          _selectedPhotoContentType = null;
        });
      }
    }
  }

  String _contentType(String fileName) {
    return switch (fileName.toLowerCase().split('.').last) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'avif' => 'image/avif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _saveProfile({bool photoOnly = false}) async {
    if (!photoOnly && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final authService = AuthServiceScope.of(context);
    if (authService == null) return;
    if ((_selectedPhotoBytes?.length ?? 0) >= 5 * 1024 * 1024) {
      _showMessage('profilePhotoTooLarge'.tr(), isError: true);
      return;
    }

    setState(() => _busy = true);
    try {
      await authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        photoBytes: _selectedPhotoBytes,
        photoContentType: _selectedPhotoContentType,
      );
      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = null;
        _selectedPhotoContentType = null;
        _isEditing = false;
        _profileFieldsEdited = false;
        _loadedProfileIdentity = null;
        _syncProfileFields(authService.currentUser);
      });
      _showMessage('profileSaved'.tr());
    } catch (error) {
      if (!mounted) return;
      final message = error is FirebaseException
          ? 'profileSaveErrorWithCode'.tr(namedArgs: {'code': error.code})
          : 'profileSaveError'.tr();
      _showMessage(message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
