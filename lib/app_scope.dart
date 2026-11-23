import 'package:flutter/material.dart';

import 'services/app_state.dart';

/// InheritedNotifier: jab bhi AppState notify kare, connected UI rebuild hoti hai.
/// Koi external state-management package ki zarurat nahi.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState app,
    required super.child,
  }) : super(notifier: app);

  /// build() ke andar use karein (rebuild chahiye).
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  /// initState() ke andar use karein (dependency register nahi chahiye).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
