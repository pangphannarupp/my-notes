import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import '../models/checklist_model.dart';
import '../models/expense_model.dart';

class DBHelper {
  static const String dbName = 'mynotes.db';
  static const int dbVersion = 2;

  static const String tableNotes = 'notes';
  static const String tableChecklists = 'checklists';
  static const String tableExpenses = 'expenses';

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $tableNotes');
      await db.execute('DROP TABLE IF EXISTS $tableChecklists');
      await db.execute('DROP TABLE IF EXISTS $tableExpenses');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        checklistItems TEXT,
        drawingImagePath TEXT,
        audioFilePath TEXT,
        reminderDate TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableChecklists(
        id TEXT PRIMARY KEY,
        title TEXT,
        items TEXT,
        reminderDate TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExpenses(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        category TEXT,
        date TEXT,
        createdAt TEXT
      )
    ''');
  }

  // --- CRUD for Notes ---
  Future<int> insertNote(NoteModel note) async {
    Database db = await instance.database;
    return await db.insert(tableNotes, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteModel>> getNotes() async {
    Database db = await instance.database;
    var notes = await db.query(tableNotes, orderBy: 'updatedAt DESC');
    return notes.isNotEmpty ? notes.map((c) => NoteModel.fromMap(c)).toList() : [];
  }

  Future<int> updateNote(NoteModel note) async {
    Database db = await instance.database;
    return await db.update(tableNotes, note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(String id) async {
    Database db = await instance.database;
    return await db.delete(tableNotes, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD for Checklists ---
  Future<int> insertChecklist(ChecklistModel checklist) async {
    Database db = await instance.database;
    return await db.insert(tableChecklists, checklist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChecklistModel>> getChecklists() async {
    Database db = await instance.database;
    var lists = await db.query(tableChecklists, orderBy: 'updatedAt DESC');
    return lists.isNotEmpty ? lists.map((c) => ChecklistModel.fromMap(c)).toList() : [];
  }

  Future<int> updateChecklist(ChecklistModel checklist) async {
    Database db = await instance.database;
    return await db.update(tableChecklists, checklist.toMap(), where: 'id = ?', whereArgs: [checklist.id]);
  }

  Future<int> deleteChecklist(String id) async {
    Database db = await instance.database;
    return await db.delete(tableChecklists, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD for Expenses ---
  Future<int> insertExpense(ExpenseModel expense) async {
    Database db = await instance.database;
    return await db.insert(tableExpenses, expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ExpenseModel>> getExpenses() async {
    Database db = await instance.database;
    var expenses = await db.query(tableExpenses, orderBy: 'date DESC');
    return expenses.isNotEmpty ? expenses.map((c) => ExpenseModel.fromMap(c)).toList() : [];
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    Database db = await instance.database;
    return await db.update(tableExpenses, expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(String id) async {
    Database db = await instance.database;
    return await db.delete(tableExpenses, where: 'id = ?', whereArgs: [id]);
  }
}
