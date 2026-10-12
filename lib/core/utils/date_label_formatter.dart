const _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatRecentDateLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final localDate = _dateOnly(date.toLocal());
  final today = _dateOnly(current.toLocal());
  final yesterday = today.subtract(const Duration(days: 1));

  if (localDate == today) {
    return 'Today';
  }

  if (localDate == yesterday) {
    return 'Yesterday';
  }

  return '${_monthLabels[localDate.month - 1]} ${localDate.day}';
}

String formatDetailedDateLabel(DateTime date) {
  final localDate = date.toLocal();
  final minute = localDate.minute.toString().padLeft(2, '0');

  return '${_monthLabels[localDate.month - 1]} '
      '${localDate.day}, ${localDate.year} • ${localDate.hour}:$minute';
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
