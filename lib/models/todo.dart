class Todo {
  final String id;
  final String ideaId;
  final String title;
  final String? note;
  final bool done;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.ideaId,
    required this.title,
    this.note,
    this.done = false,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      ideaId: json['ideaId'] as String,
      title: json['title'] as String,
      note: json['note'] as String?,
      done: json['done'] as bool,
      dueDate: json['dueDate'] != null ?
          DateTime.parse(json['dueDate'] as String) : null,
      completedAt: json['completedAt'] != null ?
          DateTime.parse(json['completedAt'] as String) : null,
      createdAt: json['createdAt'] != null ?
          (json['createdAt'] is DateTime ?
              json['createdAt'] as DateTime :
              DateTime.parse(json['createdAt'] as String)) :
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ideaId': ideaId,
      'title': title,
      'note': note,
      'done': done,
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? ideaId,
    String? title,
    String? note,
    bool? done,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      title: title ?? this.title,
      note: note ?? this.note,
      done: done ?? this.done,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Todo toggleComplete() {
    return copyWith(done: !done);
  }

  bool get isOverdue {
    if (done || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    return dueDate!.difference(now).inDays;
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, done: $done)';
  }
}