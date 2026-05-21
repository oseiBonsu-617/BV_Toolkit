import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get() async {
    _db ??= await openDatabase(
      p.join(await getDatabasesPath(), 'bv_toolkit.db'),
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            dob TEXT,
            gender TEXT,
            mrn TEXT,
            phone TEXT,
            email TEXT,
            chief_complaint TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE test_sessions (
            id TEXT PRIMARY KEY,
            patient_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            date TEXT NOT NULL,
            visit_note TEXT,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE test_sessions (
              id TEXT PRIMARY KEY,
              patient_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              date TEXT NOT NULL,
              visit_note TEXT,
              data TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
    return _db!;
  }
}
