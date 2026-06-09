import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/note_model.dart';
import '../models/checklist_model.dart';
import '../database/db_helper.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier() : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final notes = await DBHelper.instance.getNotes();
    state = notes;
  }

  Future<void> addNote(NoteModel note) async {
    await DBHelper.instance.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    await DBHelper.instance.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await DBHelper.instance.deleteNote(id);
    await loadNotes();
  }
}

final checklistsProvider = StateNotifierProvider<ChecklistsNotifier, List<ChecklistModel>>((ref) {
  return ChecklistsNotifier();
});

class ChecklistsNotifier extends StateNotifier<List<ChecklistModel>> {
  ChecklistsNotifier() : super([]) {
    loadChecklists();
  }

  Future<void> loadChecklists() async {
    final checklists = await DBHelper.instance.getChecklists();
    state = checklists;
  }

  Future<void> addChecklist(ChecklistModel checklist) async {
    await DBHelper.instance.insertChecklist(checklist);
    await loadChecklists();
  }

  Future<void> updateChecklist(ChecklistModel checklist) async {
    await DBHelper.instance.updateChecklist(checklist);
    await loadChecklists();
  }

  Future<void> deleteChecklist(String id) async {
    await DBHelper.instance.deleteChecklist(id);
    await loadChecklists();
  }
}
