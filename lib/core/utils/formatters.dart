import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • h:mm a').format(dateTime);
  }

  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}
