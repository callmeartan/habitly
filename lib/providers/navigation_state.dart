import 'package:flutter/material.dart';

class NavigationState extends InheritedWidget {
  final Function(int) onNavigate;

  const NavigationState({
    super.key,
    required this.onNavigate,
    required super.child,
  });

  static NavigationState? of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<NavigationState>()?.widget as NavigationState?;
  }

  @override
  bool updateShouldNotify(NavigationState oldWidget) {
    return oldWidget.onNavigate != onNavigate;
  }
} 