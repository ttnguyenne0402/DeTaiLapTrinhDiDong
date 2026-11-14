import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tạo bảng lưu trữ Hóa đơn
    await db.execute('''
      CREATE TABLE local_invoices (
        id TEXT PRIMARY KEY,
        invoiceCode TEXT NOT NULL,
        billingMonth TEXT NOT NULL,
        issueDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // 2. Tạo bảng lưu trữ Thông báo
    await db.execute('''
      CREATE TABLE local_notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER NOT NULL, -- 0: false, 1: true
        createdAt TEXT NOT NULL
      )
    ''');
    // 3. Tạo bảng lưu trữ Hợp đồng
    await db.execute('''
      CREATE TABLE local_contracts (
        id TEXT PRIMARY KEY,
        contractCode TEXT NOT NULL,
        roomId TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        rent REAL NOT NULL,
        deposit REAL NOT NULL,
        paymentCycle TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // --- CÁC HÀM XỬ LÝ HÓA ĐƠN ---

  Future<void> insertInvoices(List<dynamic> invoices) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var inv in invoices) {
      batch.insert(
        'local_invoices',
        {
          'id': inv['id'],
          'invoiceCode': inv['invoiceCode'],
          'billingMonth': inv['billingMonth'],
          'issueDate': inv['issueDate'],
          'dueDate': inv['dueDate'],
          'subtotal': inv['subtotal'],
          'discount': inv['discount'],
          'total': inv['total'],
          'status': inv['status'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List> getLocalInvoices() async {
    final db = await instance.database;
    return await db.query('local_invoices', orderBy: 'issueDate DESC');
  }

  // --- CÁC HÀM XỬ LÝ THÔNG BÁO ---

  Future<void> insertNotifications(List<dynamic> notifications) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var notif in notifications) {
      batch.insert(
        'local_notifications',
        {
          'id': notif['id'],
          'title': notif['title'],
          'message': notif['message'],
          'type': notif['type'],
          'isRead': notif['isRead'] == true ? 1 : 0,
          'createdAt': notif['createdAt'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List> getLocalNotifications() async {
    final db = await instance.database;
    return await db.query('local_notifications');
  }
  // --- CÁC HÀM XỬ LÝ HỢP ĐỒNG ---

  Future<void> insertContracts(List<dynamic> contracts) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var contract in contracts) {
      batch.insert(
        'local_contracts',
        {
          'id': contract['id'],
          'contractCode': contract['contractCode'] ?? '',
          'roomId': contract['roomId'] ?? '',
          'startDate': contract['startDate'] ?? '',
          'endDate': contract['endDate'] ?? '',
          'rent': contract['rent'] ?? 0,
          'deposit': contract['deposit'] ?? 0,
          'paymentCycle': contract['paymentCycle'] ?? '',
          'status': contract['status'] ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List> getLocalContracts() async {
    final db = await instance.database;
    return await db.query('local_contracts', orderBy: 'startDate DESC');
  }
}