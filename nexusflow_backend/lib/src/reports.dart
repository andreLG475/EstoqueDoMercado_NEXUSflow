/// Calcula a data de início de um período de relatório ("today", "week",
/// "month", "year" ou "all"), espelhando a lógica que existia no frontend.
DateTime periodStart(String period) {
  final now = DateTime.now();
  switch (period) {
    case 'today':
      return DateTime(now.year, now.month, now.day);
    case 'week':
      return now.subtract(const Duration(days: 7));
    case 'month':
      return DateTime(now.year, now.month - 1, now.day);
    case 'year':
      return DateTime(now.year - 1, now.month, now.day);
    default:
      return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
