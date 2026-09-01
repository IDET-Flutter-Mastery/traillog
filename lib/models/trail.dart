/// The one data shape used across every checkpoint today.
///
/// This class is already complete — nothing to do here. Focus your time
/// on the TODOs in storage/ and repositories/.
///
/// Fixed from the earlier version: toJson() now includes every field.
/// It's used for two different jobs — building a network request body,
/// AND saving a full local copy to Hive — and it has to round-trip
/// perfectly for the second job, or the cache silently loses data
/// (id, createdAt, pendingSync) every time it's written.
class Trail {
  final String id;
  final String name;
  final bool completed;
  final String createdAt;

  /// True only for trails that were added while offline and haven't
  /// reached the server yet. Used by CP4.
  final bool pendingSync;

  Trail({
    required this.id,
    required this.name,
    required this.completed,
    required this.createdAt,
    this.pendingSync = false,
  });

  factory Trail.fromJson(Map<String, dynamic> json) {
    return Trail(
      id: json['id'].toString(),
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'].toString(),
      pendingSync: json['pendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'completed': completed,
        'createdAt': createdAt,
        'pendingSync': pendingSync,
      };

  /// Handy for flipping one field without retyping the rest — used by
  /// the Quick Challenge and by CP4's offline write path.
  Trail copyWith({
    String? id,
    String? name,
    bool? completed,
    String? createdAt,
    bool? pendingSync,
  }) {
    return Trail(
      id: id ?? this.id,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
