/// The child being tracked on the active journey.
class Child {
  const Child({
    required this.name,
    required this.grade,
    required this.avatarInitials,
  });

  final String name;
  final String grade;
  final String avatarInitials;

  /// First name only — used where the UI addresses the parent conversationally.
  String get firstName => name.split(' ').first;
}
