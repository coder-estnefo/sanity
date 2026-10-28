/// Number of full calendar days between [quit] and [now].
///
/// Uses calendar dates (not 24h spans) so DST changes and time of day never
/// skew the count. Future quit dates yield 0.
int daysFree(DateTime quit, DateTime now) {
  final a = DateTime(quit.year, quit.month, quit.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
  return diff < 0 ? 0 : diff;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

