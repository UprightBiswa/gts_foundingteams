/// The GTS driver assigned to the journey.
class Driver {
  const Driver({
    required this.name,
    required this.rating,
    required this.totalTrips,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.phoneNumber,
    required this.avatarInitials,
    required this.isVerified,
  });

  final String name;
  final double rating;
  final int totalTrips;
  final String vehicleModel;
  final String vehiclePlate;
  final String phoneNumber;
  final String avatarInitials;

  /// Whether GTS background checks are current — surfaced as a badge, because
  /// "who is driving my child" is the first question a parent asks.
  final bool isVerified;

  String get ratingLabel => rating.toStringAsFixed(1);
}
