import 'package:flutter/widgets.dart';

import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/services/auth_service.dart';

class AuthServiceScope extends InheritedWidget {
  const AuthServiceScope({
    required this.service,
    required this.user,
    required super.child,
    super.key,
  });

  final AuthService? service;
  final AuthUser? user;

  static AuthServiceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthServiceScope>();

  static AuthService? of(BuildContext context) => maybeOf(context)?.service;

  @override
  bool updateShouldNotify(AuthServiceScope oldWidget) =>
      service != oldWidget.service || user != oldWidget.user;
}
