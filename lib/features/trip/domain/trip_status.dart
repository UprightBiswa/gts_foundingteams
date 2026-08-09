/// Lifecycle of a single school-run journey, worded the way a parent reads it.
enum TripStatus {
  pickedUp('Picked up', 'Your child has boarded the vehicle'),
  enRoute('On the way', 'Heading home from school'),
  delayed('Delayed', 'The vehicle is not moving right now'),
  arriving('Arriving soon', 'Almost at the drop-off point'),
  completed('Dropped off', 'Your child has reached home safely');

  const TripStatus(this.label, this.description);

  final String label;
  final String description;

  bool get isFinished => this == TripStatus.completed;
}
