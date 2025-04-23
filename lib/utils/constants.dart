// utils/constants.dart
import 'package:flutter/material.dart';

/// アプリケーション全体で使用する定数を定義するクラス
class AppConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Colors
  static final Color primaryColor = Colors.blue;
  static final Color secondaryColor = Colors.orange;
  static final Color accentColor = Colors.green;
  static final Color warningColor = Colors.amber;
  static final Color dangerColor = Colors.red;
  static final Color progressColor = Colors.purple;

  // Timer extensions
  static const Duration captureSaveExtension = Duration(days: 7);
  static const Duration validateAnswerExtension = Duration(hours: 48);
  static const Duration buildTodoExtension = Duration(hours: 24);

  // App name
  static const String appName = 'アイデアランチャー';

  // Default idea expiration days
  static const int defaultIdeaExpirationDays = 7;

  // Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
