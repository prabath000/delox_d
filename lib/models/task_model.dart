class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double progress;
  final List<String> avatars;
  final DateTime date;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.progress = 0.0,
    this.avatars = const [],
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'progress': progress,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'] ?? 'guest',
      title: map['title'],
      description: map['description'],
      progress: (map['progress'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      isCompleted: map['isCompleted'] == 1,
      avatars: [],
    );
  }
}
