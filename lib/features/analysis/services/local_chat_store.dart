import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

typedef ChatRow = Map<String, dynamic>;

class LocalChatStore {
  LocalChatStore(this.db) {
    db.execute('CREATE TABLE IF NOT EXISTS device(id TEXT PRIMARY KEY)');
    db.execute('CREATE TABLE IF NOT EXISTS deleted(thread TEXT PRIMARY KEY)');
    db.execute(
      '''CREATE TABLE IF NOT EXISTS turns(
      id TEXT PRIMARY KEY, thread TEXT NOT NULL, stamp INTEGER NOT NULL,
      question TEXT NOT NULL, answer TEXT NOT NULL, status TEXT NOT NULL, sources TEXT NOT NULL)''',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS chat_order ON turns(thread,stamp,id)',
    );
    db.execute(
      'INSERT INTO device SELECT ? WHERE NOT EXISTS(SELECT 1 FROM device)',
      [const Uuid().v4()],
    );
    device = db.select('SELECT id FROM device').first['id'] as String;
  }
  final Database db;
  late final String device;
  static Future<LocalChatStore> open(String user) async {
    final dir = await getApplicationSupportDirectory();
    return LocalChatStore(sqlite3.open(p.join(dir.path, 'chat-$user.sqlite')));
  }

  bool hasTurn(String id) =>
      db.select('SELECT 1 FROM turns WHERE id=?', [id]).isNotEmpty;

  bool deleted(String thread) =>
      db.select('SELECT 1 FROM deleted WHERE thread=?', [thread]).isNotEmpty;
  void remove(String thread) {
    db.execute('BEGIN');
    try {
      db.execute('INSERT OR IGNORE INTO deleted VALUES (?)', [thread]);
      db.execute('DELETE FROM turns WHERE thread=?', [thread]);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  bool save(ChatRow row) {
    if (deleted(row['thread_id'] as String)) return false;
    db.execute(
      '''INSERT INTO turns VALUES(?,?,?,?,?,?,?)
      ON CONFLICT(id) DO UPDATE SET answer=excluded.answer,status=excluded.status,sources=excluded.sources
      WHERE turns.status NOT IN ('done','failed') AND
      (turns.status<>excluded.status OR turns.answer<>excluded.answer OR turns.sources<>excluded.sources)''',
      [
        row['id'],
        row['thread_id'],
        DateTime.parse(row['created_at'] as String).microsecondsSinceEpoch,
        row['question'],
        row['answer'],
        row['status'],
        jsonEncode(row['sources']),
      ],
    );
    return db.updatedRows != 0;
  }

  List<ChatRow> rooms(ChatRow? after) => db
      .select(
        '''WITH rooms AS (
    SELECT thread AS id,question AS title,MAX(stamp) OVER(PARTITION BY thread) AS last_at,
    ROW_NUMBER() OVER(PARTITION BY thread ORDER BY stamp,id) AS n FROM turns)
    SELECT id,title,last_at FROM rooms WHERE n=1
    AND (? IS NULL OR (last_at,id)<(?,?)) ORDER BY last_at DESC,id DESC LIMIT 30''',
        [after?['last_at'], after?['last_at'], after?['id']],
      )
      .toList();

  List<ChatRow> history(String thread) => db
      .select(
        'SELECT * FROM turns WHERE thread=? ORDER BY stamp DESC,id DESC',
        [thread],
      )
      .map((r) => {...r, 'sources': jsonDecode(r['sources'] as String)})
      .toList();

  List<ChatRow> context(String thread) => db
      .select(
        "SELECT substr(question,1,2000) AS question,substr(answer,1,700) AS answer FROM turns WHERE thread=? AND status='done' ORDER BY stamp DESC,id DESC LIMIT 3",
        [thread],
      )
      .reversed
      .toList();
}
