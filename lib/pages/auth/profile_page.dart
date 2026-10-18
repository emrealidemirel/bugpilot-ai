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
    _syncProfileFields(AuthServiceScope.maybeOf(context)?.user);
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
                Center(child: _profilePhoto(user)),
                const SizedBox(height: AppDimensions.spacingSmall),
                Center(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _choosePhotoSource,
                    icon: const Icon(Icons.edit_rounded),
                    label: Text('changeProfilePhoto'.tr()),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        decoration: InputDecoration(
                          labelText: 'firstNameLabel'.tr(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        decoration: InputDecoration(
                          labelText: 'lastNameLabel'.tr(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      TextFormField(
                        initialValue: user?.email ?? '',
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.emailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                FilledButton.icon(
                  onPressed: user == null || _busy ? null : _saveProfile,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _busy ? context.l10n.pleaseWait : 'saveProfile'.tr(),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                OutlinedButton.icon(
                  onPressed: user == null || _busy
                      ? null
                      : () => AuthServiceScope.of(context)?.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.l10n.signOut),
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

    return CircleAvatar(
      radius: 62,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.person_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : null,
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
    if (source == null) return;

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
    } catch (_) {
      if (mounted) _showMessage('profilePhotoPickError'.tr(), isError: true);
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
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
