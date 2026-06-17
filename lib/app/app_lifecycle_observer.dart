import 'package:flutter/widgets.dart';

final class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver({this.onPaused, this.onResumed});

  final VoidCallback? onPaused;
  final VoidCallback? onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        onPaused?.call();
      case AppLifecycleState.resumed:
        onResumed?.call();
      case AppLifecycleState.detached:
        break;
    }
  }
}
