
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FavoriteService {
  FavoriteService._();

  static final FavoriteService instance = FavoriteService._();

  static Database? _database;

  // Thông báo cho các màn hình khi danh sách yêu thích thay đổi.
  final ValueNotifier<int> favoritesChanged = ValueNotifier<int>(0);

  void _notifyChanged() {
    favoritesChanged.value++;
  }

  // ============================================================
  // KHỞI TẠO DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, 'tro_oi_favorites.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            room_id TEXT PRIMARY KEY,
            room_json TEXT NOT NULL,
            saved_at INTEGER NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  // ============================================================
  // THÊM PHÒNG YÊU THÍCH
  // ============================================================

  Future<void> addFavorite(Map<String, dynamic> room) async {
    final db = await database;

    final roomId = room['id']?.toString();

    if (roomId == null || roomId.isEmpty) {
      throw Exception('Không tìm thấy mã phòng');
    }

    await db.insert(
      'favorites',
      {
        'room_id': roomId,
        'room_json': jsonEncode(room),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _notifyChanged();
  }

  // ============================================================
  // XÓA PHÒNG YÊU THÍCH
  // ============================================================

  Future<void> removeFavorite(String roomId) async {
    final db = await database;

    await db.delete(
      'favorites',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );

    _notifyChanged();
  }

  // ============================================================
  // LẤY DANH SÁCH PHÒNG YÊU THÍCH
  // ============================================================

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;

    final rows = await db.query(
      'favorites',
      orderBy: 'saved_at DESC',
    );

    return rows.map((row) {
      final room = Map<String, dynamic>.from(
        jsonDecode(row['room_json'] as String) as Map,
      );

      room['image'] ??= '';

      room['amenities'] = List<String>.from(
        room['amenities'] ?? [],
      );

      return room;
    }).toList();
  }

  // ============================================================
  // KIỂM TRA PHÒNG ĐÃ ĐƯỢC YÊU THÍCH CHƯA
  // ============================================================

  Future<bool> isFavorite(String roomId) async {
    final db = await database;

    final result = await db.query(
      'favorites',
      columns: ['room_id'],
      where: 'room_id = ?',
      whereArgs: [roomId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // LẤY DANH SÁCH ID PHÒNG YÊU THÍCH
  // ============================================================

  Future<Set<String>> getFavoriteIds() async {
    final db = await database;

    final rows = await db.query(
      'favorites',
      columns: ['room_id'],
    );

    return rows
        .map((row) => row['room_id'].toString())
        .toSet();
  }
}
