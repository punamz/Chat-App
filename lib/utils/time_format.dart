import 'package:intl/intl.dart';

String dayFormat(String microsecondsSinceEpoch) {
  int time = int.parse(microsecondsSinceEpoch);
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(time);
  DateFormat formatter =
      isToday(dateTime) ? DateFormat.jm() : DateFormat('dd MMM kk:mm');
  return formatter.format(dateTime);
}

bool isToday(DateTime dateTime) {
  final now = DateTime.now();
  return (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day);
}
