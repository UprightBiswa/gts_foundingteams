import 'package:flutter/material.dart';

/// Single source of truth for colour in the app.
///
/// Everything is expressed as a semantic role (`safe`, `warning`, `danger`)
/// rather than a raw hue, so the safety states stay consistent between the
/// banner, the map marker, the metric tiles and the SOS flow.
abstract final class AppColors {
  // Brand
  static const Color brand = Color(0xFF2C5CFF);
  static const Color brandDark = Color(0xFF1B3FCC);
  static const Color brandSoft = Color(0xFFEAF0FF);

  // Neutrals
  static const Color ink = Color(0xFF0C1B33);
  static const Color inkSecondary = Color(0xFF41506B);
  static const Color inkMuted = Color(0xFF7385A0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF4F6FB);
  static const Color border = Color(0xFFE4E9F2);

  // Semantic safety states
  static const Color safe = Color(0xFF12A366);
  static const Color safeSoft = Color(0xFFE6F6EF);
  static const Color warning = Color(0xFFF08C00);
  static const Color warningSoft = Color(0xFFFFF4E2);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color sos = Color(0xFFD92D20);

  // Map palette
  static const Color mapLand = Color(0xFFEDF1F8);
  static const Color mapBlock = Color(0xFFE1E8F3);
  static const Color mapBlockAlt = Color(0xFFE8EDF6);
  static const Color mapPark = Color(0xFFDBEDDF);
  static const Color mapWater = Color(0xFFCFE2F5);
  static const Color mapRoad = Color(0xFFFDFDFF);
  static const Color routeIdle = Color(0xFFC2CFE6);
}
