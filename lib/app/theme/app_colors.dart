import 'package:flutter/material.dart';

/// Centralized color palette. Contrast ratios are kept deliberately high
/// (see Phase 7.1 of the blueprint — elderly/non-tech-savvy accessibility)
/// rather than relying on default Material tones.
abstract class AppColors {
  // --- Brand ---
  static const primary = Color(0xFF1B7A43); // village green
  static const primaryDark = Color(0xFF125C30);
  static const secondary = Color(0xFFE8A33D); // warm accent (market/harvest tone)

  // --- Status colors (used for large order-status banners, Phase 7.1) ---
  static const statusPending = Color(0xFF9E9E9E);
  static const statusAccepted = Color(0xFF2E7D32);
  static const statusPreparing = Color(0xFFE8A33D);
  static const statusInTransit = Color(0xFF1565C0);
  static const statusDelivered = Color(0xFF1B7A43);
  static const statusCancelled = Color(0xFFC62828);

  // --- Surfaces ---
  static const background = Color(0xFFFAFAF7);
  static const surface = Colors.white;
  static const warningBg = Color(0xFFFFF3CD);

  // --- Text (high contrast per accessibility guidelines) ---
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textOnPrimary = Colors.white;

  // --- Placeholders ---
  static const shimmerBase = Color(0xFFE0E0E0);
  static const imagePlaceholderBg = Color(0xFFEFEFEF);
  static const imagePlaceholderIcon = Color(0xFFBDBDBD);

  static const error = Color(0xFFC62828);
  static const divider = Color(0xFFE0E0E0);
}
