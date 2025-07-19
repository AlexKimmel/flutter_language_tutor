import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'chat_history.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> addMessage(String text, bool isUser) async {
    final db = await database;
    //print('Adding message: $text, isUser: $isUser');
    return await db.insert('chat_messages', {
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    //print('DEBUG: getChatHistory returned ${result.length} messages');
    return result;
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_messages');
  }

  Future<void> deleteMessage(int id) async {
    final db = await database;
    await db.delete('chat_messages', where: 'id = ?', whereArgs: [id]);
  }
}
