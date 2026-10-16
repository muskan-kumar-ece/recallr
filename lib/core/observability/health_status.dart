/// Operational health status classifications.
enum HealthState {
  healthy,
  degraded,
  unavailable,
  unknown;

  bool get isOperational => this == HealthState.healthy || this == HealthState.degraded;
}

/// Health diagnostic status for a specific system or subsystem.
class ComponentHealth {
  final String name;
  final HealthState state;
  final DateTime lastChecked;
  final int? latencyMs;
  final String? message;

  ComponentHealth({
    required this.name,
    required this.state,
    DateTime? lastChecked,
    this.latencyMs,
    this.message,
  }) : lastChecked = lastChecked ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'state': state.name,
      'lastChecked': lastChecked.toIso8601String(),
      if (latencyMs != null) 'latencyMs': latencyMs,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() => 'ComponentHealth($name: ${state.name}${latencyMs != null ? ", ${latencyMs}ms" : ""})';
}

/// Overall system health report.
class SystemHealthReport {
  final HealthState overallState;
  final List<ComponentHealth> components;
  final DateTime timestamp;

  SystemHealthReport({
    required this.overallState,
    required this.components,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'overallState': overallState.name,
      'timestamp': timestamp.toIso8601String(),
      'components': components.map((c) => c.toMap()).toList(),
    };
  }
}