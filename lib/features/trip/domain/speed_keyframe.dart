/// One point on the scripted speed profile that drives the simulation.
///
/// The simulator linearly interpolates between consecutive keyframes and holds
/// the final value, so a whole journey — including the overspeeding burst and
/// the roadside stop — is described by a short, readable table of numbers.
class SpeedKeyframe {
  const SpeedKeyframe(this.second, this.speedKmh);

  /// Simulated journey time, in seconds since pickup.
  final double second;

  /// Target speed at that moment, in km/h.
  final double speedKmh;
}
