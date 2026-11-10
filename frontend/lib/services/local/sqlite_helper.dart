import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteHelper {
  static final SqliteHelper instance = SqliteHelper._init();
  static Database? _database;

  SqliteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quanlyphongtro_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE draft_posts ADD COLUMN room_id TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE draft_posts ADD COLUMN amenities TEXT;');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Bảng lưu trữ tin đăng nháp cục bộ (Offline / Local Draft)
    await db.execute('''
      CREATE TABLE draft_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id TEXT,
        building_name TEXT,
        room_name TEXT,
        title TEXT NOT NULL,
        description TEXT,
        price TEXT,
        amenities TEXT,
        image TEXT,
        created_at TEXT
      )
    ''');

    // Dữ liệu nháp mẫu ban đầu
    await db.insert('draft_posts', {
      'room_id': 'room_101',
      'building_name': 'Chung cư Mini Bình Thạnh',
      'room_name': 'Phòng 402',
      'title': 'Phòng studio full tiện nghi ban công rộng',
      'description': 'Phòng có máy lạnh, tủ lạnh, giường nệm cao cấp.',
      'price': '4.800.000đ/tháng',
      'amenities': 'Wifi,Điều hòa,Tủ lạnh,An ninh 24/7',
      'image': 'frontend/assets/images/anhPhongDemo.jpg',
      'created_at': '05/10/2026',
    });
  }

  // --- CÁC HÀM CRUD CHO BẢN NHÁP TIN ĐĂNG (DRAFT POSTS) ---

  // Thêm tin nháp vào SQLite
  Future<int> insertDraftPost(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('draft_posts', data);
  }

  // Cập nhật tin nháp trong SQLite
  Future<int> updateDraftPost(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'draft_posts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy tất cả tin nháp từ SQLite
  Future<List<Map<String, dynamic>>> getDraftPosts() async {
    final db = await instance.database;
    return await db.query('draft_posts', orderBy: 'id DESC');
  }

  // Xóa tin nháp sau khi đã gửi duyệt lên SQL Server
  Future<int> deleteDraftPost(int id) async {
    final db = await instance.database;
    return await db.delete(
      'draft_posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Đóng database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
