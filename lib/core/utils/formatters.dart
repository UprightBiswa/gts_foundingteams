/// Display formatting helpers.
///
/// Kept in one place so that "1.2 km" and "8 min" read identically wherever
/// they appear — a parent scanning the screen should never have to reconcile
/// two different renderings of the same quantity.
abstract final class Formatters {
  /// `450 m`, `1.2 km`
  static String distance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// `< 1 min`, `8 min`, `1 hr 05 min`
  static String duration(Duration value) {
    if (value.inSeconds <= 30) return '< 1 min';

    final totalMinutes = (value.inSeconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
  }

  /// Speed rounded to whole km/h — decimals imply a precision GPS never has.
  static String speed(double kmh) => kmh.round().toString();

  /// `3:42 PM`
  static String clockTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// `02:14` — elapsed journey time.
  static String stopwatch(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
