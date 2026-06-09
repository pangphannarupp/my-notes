import 'dart:convert';
import 'checklist_model.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final List<ChecklistItem>? checklistItems;
  final String? drawingImagePath;
  final String? audioFilePath;
  final DateTime? reminderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.checklistItems,
    this.drawingImagePath,
    this.audioFilePath,
    this.reminderDate,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    List<ChecklistItem>? checklistItems,
    String? drawingImagePath,
    String? audioFilePath,
    DateTime? reminderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      checklistItems: checklistItems ?? this.checklistItems,
      drawingImagePath: drawingImagePath ?? this.drawingImagePath,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      reminderDate: reminderDate ?? this.reminderDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'checklistItems': checklistItems != null ? jsonEncode(checklistItems!.map((e) => e.toMap()).toList()) : null,
      'drawingImagePath': drawingImagePath,
      'audioFilePath': audioFilePath,
      'reminderDate': reminderDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    List<ChecklistItem>? items;
    if (map['checklistItems'] != null) {
      var itemsList = jsonDecode(map['checklistItems']) as List;
      items = itemsList.map((e) => ChecklistItem.fromMap(e)).toList();
    }
    
    return NoteModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      checklistItems: items,
      drawingImagePath: map['drawingImagePath'],
      audioFilePath: map['audioFilePath'],
      reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
