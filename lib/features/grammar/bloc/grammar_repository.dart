import 'package:language_tutor/data/models/gramamr_card.dart';
import 'package:sqflite/sqflite.dart';

class GrammarRepository {
  static final GrammarRepository _instance = GrammarRepository._internal();
  factory GrammarRepository() => _instance;
  GrammarRepository._internal();
  Database? _dataBase;

  Future<Database> get database async {
    if (_dataBase != null) return _dataBase!;

    _dataBase = await _initDB();
    return _dataBase!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      '$path/grammar_notes.db',
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE grammar_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            messageId INTEGER,
            example TEXT NOT NULL,
            explanation TEXT NOT NULL,
            text TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add messageId column to existing table
          await db.execute(
            'ALTER TABLE grammar_notes ADD COLUMN messageId INTEGER',
          );
        }
      },
    );
  }

  Future<List<GrammarCard>> getAllGrammarCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grammar_notes');

    return List.generate(maps.length, (i) {
      return GrammarCard.fromMap(maps[i]);
    });
  }

  Future<List<GrammarCard>> getGrammarCardsByMessageId(int messageId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'grammar_notes',
        where: 'messageId = ?',
        whereArgs: [messageId],
      );

      return List.generate(maps.length, (i) {
        return GrammarCard.fromMap(maps[i]);
      });
    } catch (e) {
      // If the column doesn't exist, return empty list
      // This is a fallback for migration issues
      print('Error querying by messageId: $e');
      return [];
    }
  }

  Future<void> addGrammarCard(GrammarCard card) async {
    final db = await database;
    await db.insert(
      'grammar_notes',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGrammarCard(GrammarCard card) async {
    final db = await database;
    await db.update(
      'grammar_notes',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteGrammarCard(int id) async {
    final db = await database;
    await db.delete('grammar_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<GrammarCard> getRandomGrammarCard() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grammar_notes',
      orderBy: 'RANDOM()',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GrammarCard.fromMap(maps.first);
    } else {
      throw Exception('No grammar cards found');
    }
  }

  // Method to clear and recreate the database if migration fails
  Future<void> clearDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = '$path/grammar_notes.db';

    // Close existing database connection
    if (_dataBase != null) {
      await _dataBase!.close();
      _dataBase = null;
    }

    // Delete the database file
    await deleteDatabase(dbPath);

    // Reinitialize the database
    _dataBase = await _initDB();
  }
}
