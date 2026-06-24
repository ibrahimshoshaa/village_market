import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text scale is deliberately larger than Material defaults — base body text
/// is 18sp (vs Material's 14-16sp default), per the elder-friendly
/// accessibility guidelines in Phase 7.1 of the blueprint. Never go below
/// w400 weight; thin weights are hard to read for users with age-related
/// vision changes, especially in Arabic script.
abstract class AppTextStyles {
  static const _fontFamily = 'Cairo'; // swap once the font asset is added to pubspec.yaml

  static const headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18, // elder-friendly minimum, not Material's default 14-16
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const price = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );
}
