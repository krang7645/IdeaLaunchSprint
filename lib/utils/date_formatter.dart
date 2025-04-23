import 'package:intl/intl.dart';

class DateFormatter {
  /// 日付を「yyyy/MM/dd」形式でフォーマットします
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 日付を「yyyy年MM月dd日」形式でフォーマットします
  static String formatDateJapanese(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  /// 日付と時刻を「yyyy/MM/dd HH:mm」形式でフォーマットします
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  /// 相対的な時間表示を返します（例：「3日前」「1時間前」）
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}