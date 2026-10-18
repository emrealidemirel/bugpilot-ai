const _englishMonthLabels = [
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

const _turkishMonthLabels = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

String formatRecentDateLabel(
  DateTime date, {
  DateTime? now,
  String localeCode = 'en',
  String todayLabel = 'Today',
  String yesterdayLabel = 'Yesterday',
}) {
  final current = now ?? DateTime.now();
  final localDate = _dateOnly(date.toLocal());
  final today = _dateOnly(current.toLocal());
  final yesterday = today.subtract(const Duration(days: 1));

  if (localDate == today) {
    return todayLabel;
  }

  if (localDate == yesterday) {
    return yesterdayLabel;
  }

  final months = localeCode == 'tr' ? _turkishMonthLabels : _englishMonthLabels;
  return localeCode == 'tr'
      ? '${localDate.day} ${months[localDate.month - 1]}'
      : '${months[localDate.month - 1]} ${localDate.day}';
}

String formatDetailedDateLabel(DateTime date, {String localeCode = 'en'}) {
  final localDate = date.toLocal();
  final minute = localDate.minute.toString().padLeft(2, '0');
  final months = localeCode == 'tr' ? _turkishMonthLabels : _englishMonthLabels;

  final dateLabel = localeCode == 'tr'
      ? '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}'
      : '${months[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
  return '$dateLabel • ${localDate.hour}:$minute';
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
