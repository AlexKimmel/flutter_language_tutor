import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:language_tutor/features/flashcards/flashcard.dart';

class FlashcardRepository {
  static final FlashcardRepository _instance = FlashcardRepository._internal();
  factory FlashcardRepository() => _instance;
  FlashcardRepository._internal();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'flashcards.db');
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
            nextReview TEXT,
            interval INTEGER,
            easeFactor REAL,
            repetitions INTEGER
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

  Future<List<Flashcard>> getDueFlashcards() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'flashcards',
      where: 'nextReview <= ?',
      whereArgs: [now],
    );
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  //Get known flashcards
  Future<List<Flashcard>> getKnownFlashcards({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'repetitions > 0',
      orderBy: 'repetitions DESC, nextReview DESC',
      limit: limit,
    );
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<Flashcard>> getCurrentlyLearningFlashcards({
    int limit = 10,
  }) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'repetitions > 0',
      orderBy: 'nextReview ASC, repetitions ASC',
      limit: limit,
    );
    return maps.map((e) => Flashcard.fromMap(e)).toList();
  }

  Flashcard updateSRS(Flashcard card, int quality) {
    int repetitions = card.repetitions;
    double ef = card.easeFactor;
    int interval = card.interval;

    if (quality < 3) {
      repetitions = 0;
      interval = 1;
    } else {
      repetitions += 1;
      ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      ef = ef.clamp(1.3, 2.5);
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
    }

    return Flashcard(
      id: card.id,
      front: card.front,
      back: card.back,
      context: card.context,
      interval: interval,
      easeFactor: ef,
      repetitions: repetitions,
      nextReview: DateTime.now().add(Duration(days: interval)),
    );
  }
}
