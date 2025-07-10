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
      '$path/grammar_cards.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE grammar_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            example TEXT NOT NULL,
            explanation TEXT NOT NULL,
            text TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<GrammarCard>> getAllGrammarCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grammar_cards');

    return List.generate(maps.length, (i) {
      return GrammarCard.fromMap(maps[i]);
    });
  }

  Future<void> addGrammarCard(GrammarCard card) async {
    final db = await database;
    await db.insert(
      'grammar_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGrammarCard(GrammarCard card) async {
    final db = await database;
    await db.update(
      'grammar_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteGrammarCard(int id) async {
    final db = await database;
    await db.delete('grammar_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<GrammarCard> getRandomGrammarCard() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grammar_cards',
      orderBy: 'RANDOM()',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GrammarCard.fromMap(maps.first);
    } else {
      throw Exception('No grammar cards found');
    }
  }
}
