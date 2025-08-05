class DailyGoal {
  final int? id;
  final String title;
  final GoalType type;
  final int? targetCount;
  final DateTime date;
  int currentCount;
  bool isCompleted;

  DailyGoal({
    this.id,
    required this.title,
    required this.type,
    this.targetCount,
    required this.date,
    this.currentCount = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'targetCount': targetCount,
      'date': date.millisecondsSinceEpoch,
      'currentCount': currentCount,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      id: map['id'],
      title: map['title'],
      type: GoalType.values[map['type']],
      targetCount: map['targetCount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      currentCount: map['currentCount'] ?? 0,
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

enum GoalType {
  checkbox,
  counter,
}