import 'package:intl/intl.dart';

String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime parseIso(String iso) => DateTime.parse('${iso}T00:00:00.000');
