import 'package:flutter/material.dart';

/// Simple in-memory app-wide settings.
/// Note: resets on app restart since there's no local persistence
/// package (e.g. shared_preferences) added yet — fine for now,
/// easy to upgrade later without changing how screens use this.
class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  final ValueNotifier<bool> useCelsius = ValueNotifier<bool>(true);

  void toggleUnits() {
    useCelsius.value = !useCelsius.value;
  }
}
