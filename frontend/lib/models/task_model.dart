class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedBy;
  final String recurrence;
  final int priorityOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = 'To-Do',
    this.blockedBy,
    this.recurrence = 'None',
    this.priorityOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      // API sends UTC directly (ex: 2026-04-02T12:00:00Z) or naive string.
      // .toLocal() converts the parsed UTC date into the device's local timezone.
      dueDate: DateTime.parse(json['due_date']).toLocal(),
      status: json['status'],
      blockedBy: json['blocked_by'],
      recurrence: json['recurrence'],
      priorityOrder: json['priority_order'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      // API expects ISO8601 UTC. .toUtc() shifts local time to UTC properly.
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status,
      'blocked_by': blockedBy,
      'recurrence': recurrence,
      'priority_order': priorityOrder,
    };
  }
}
