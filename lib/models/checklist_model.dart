import 'dart:convert';

class ChecklistItem {
  final String title;
  bool isCompleted;

  ChecklistItem({required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {
    'title': title,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
    title: map['title'],
    isCompleted: map['isCompleted'] == 1,
  );
}

class ChecklistModel {
  final String id;
  final String title;
  final List<ChecklistItem> items;
  final DateTime? reminderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistModel({
    required this.id,
    required this.title,
    required this.items,
    this.reminderDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'items': jsonEncode(items.map((e) => e.toMap()).toList()),
      'reminderDate': reminderDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChecklistModel.fromMap(Map<String, dynamic> map) {
    var itemsList = jsonDecode(map['items']) as List;
    return ChecklistModel(
      id: map['id'],
      title: map['title'],
      items: itemsList.map((e) => ChecklistItem.fromMap(e)).toList(),
      reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
