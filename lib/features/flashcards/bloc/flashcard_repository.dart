import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fsrs/fsrs.dart';
import 'package:language_tutor/data/models/flashcard.dart';

class FlashcardRepository {
  static final FlashcardRepository _instance = FlashcardRepository._internal();
  factory FlashcardRepository() => _instance;
  FlashcardRepository._internal();
  Database? _database;
  final _scheduler = Scheduler();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'flashcards2.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE flashcards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            front TEXT NOT NULL,
            back TEXT NOT NULL,
            context TEXT,
            stability REAL DEFAULT 0.0,
            difficulty REAL DEFAULT 0.3,
            interval INTEGER DEFAULT 0,
            due TEXT,
            lastReviewed TEXT
          )
        ''');
      },
    );
  }

  Future<void> addFlashcard(Flashcard card) async {
    final db = await database;
    await db.insert(
      'flashcards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final db = await database;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteFlashcard(int id) async {
    final db = await database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = await database;
    final maps = await db.query('flashcards');
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  // Get known flashcards
  Future<List<Flashcard>> getDueFlashcards({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'lastReviewed IS NOT NULL AND due <= ?',
      orderBy: 'interval DESC, due DESC',
      whereArgs: [DateTime.now().toIso8601String()],
      limit: limit,
    );
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  // Get time of next session
  Future<DateTime?> getNextSessionTime() async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'lastReviewed IS NOT NULL AND due > ?',
      orderBy: 'due ASC',
      limit: 1,
      whereArgs: [DateTime.now().toIso8601String()],
    );
    if (maps.isEmpty) return null;
    final nextDue = DateTime.parse(maps.first['due'] as String);
    return nextDue.isAfter(DateTime.now()) ? nextDue : null;
  }

  // Get new flashcards
  Future<List<Flashcard>> getNewFlashcards({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'lastReviewed IS NULL',
      orderBy: 'due ASC',
      limit: limit,
    );
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<Flashcard> updateSRS(Flashcard card, Rating rating) async {
    // Reconstruct FSRS Card from your model
    final fsrsCard = Card(cardId: card.id!)
      ..due = card.due.toUtc()
      ..stability = card.stability
      ..difficulty = card.difficulty;

    // Review the card using FSRS
    final result = _scheduler.reviewCard(
      fsrsCard,
      rating,
      reviewDateTime: DateTime.now(),
    );

    final updatedFsrsCard = result.card;

    // Map back to your Flashcard model
    final updated = card.copyWith(
      due: updatedFsrsCard.due.toLocal(),
      stability: updatedFsrsCard.stability,
      difficulty: updatedFsrsCard.difficulty,
    );

    // Save to database
    await updateFlashcard(updated);

    return updated;
  }
}
