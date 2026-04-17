import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/device_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static Database? _database;

  static const String tableDevices = 'devices';
  static const String tableTerminalLogs = 'terminal_logs';

  // Device table columns
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnTab = 'tab';
  static const String columnCategory = 'category';
  static const String columnModel = 'model';
  static const String columnOnCommand = 'on_command';
  static const String columnOffCommand = 'off_command';
  static const String columnOnReceive = 'on_receive';
  static const String columnOffReceive = 'off_receive';
  static const String columnIcon = 'icon';
  static const String columnIsFavorite = 'is_favorite';
  static const String columnIsOn = 'is_on';
  static const String columnOrder = 'device_order';
  static const String columnLastAngle = 'last_angle';
  static const String columnCreatedAt = 'created_at';

  // Rack explicit columns (Added v3)
  static const String columnRack0Cmd = 'rack_0_cmd';
  static const String columnRack90Cmd = 'rack_90_cmd';
  static const String columnRack180Cmd = 'rack_180_cmd';
  static const String columnRack0Recv = 'rack_0_recv';
  static const String columnRack90Recv = 'rack_90_recv';
  static const String columnRack180Recv = 'rack_180_recv';

  // RFID Door Lock scenario columns (Added v5)
  static const String columnRfidScenario1Cmd = 'rfid_scenario_1_cmd';
  static const String columnRfidScenario1Msg = 'rfid_scenario_1_msg';
  static const String columnRfidScenario2Cmd = 'rfid_scenario_2_cmd';
  static const String columnRfidScenario2Msg = 'rfid_scenario_2_msg';
  static const String columnRfidScenario3Cmd = 'rfid_scenario_3_cmd';
  static const String columnRfidScenario3Msg = 'rfid_scenario_3_msg';
  static const String columnRfidScenario4Cmd = 'rfid_scenario_4_cmd';
  static const String columnRfidScenario4Msg = 'rfid_scenario_4_msg';
  static const String columnRfidScenario5Cmd = 'rfid_scenario_5_cmd';
  static const String columnRfidScenario5Msg = 'rfid_scenario_5_msg';
  static const String columnRfidScenario6Cmd = 'rfid_scenario_6_cmd';
  static const String columnRfidScenario6Msg = 'rfid_scenario_6_msg';
  static const String columnRfidScenario7Cmd = 'rfid_scenario_7_cmd';
  static const String columnRfidScenario7Msg = 'rfid_scenario_7_msg';
  static const String columnRfidLastMessage = 'rfid_last_message';

  // Auto Lock Door columns (Added v5)
  static const String columnAutoLockCommand = 'auto_lock_command';
  static const String columnAutoLockTimer = 'auto_lock_timer';
  static const String columnAutoLockState = 'auto_lock_state';

  // Terminal log columns
  static const String columnLogId = 'id';
  static const String columnLogMessage = 'message';
  static const String columnLogDirection = 'direction'; // 'tx' or 'rx'
  static const String columnLogTime = 'time';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_home_controller.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Non-destructive upgrades
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          // If we were at version 1, we ensure tables exist without dropping
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $tableDevices ($columnId TEXT PRIMARY KEY, $columnName TEXT NOT NULL, $columnTab TEXT NOT NULL, $columnCategory TEXT NOT NULL, $columnModel TEXT NOT NULL, $columnOnCommand TEXT NOT NULL, $columnOffCommand TEXT NOT NULL, $columnOnReceive TEXT NOT NULL, $columnOffReceive TEXT NOT NULL, $columnIcon TEXT NOT NULL, $columnIsFavorite INTEGER DEFAULT 0, $columnIsOn INTEGER DEFAULT 0, $columnOrder INTEGER NOT NULL, $columnCreatedAt TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $tableTerminalLogs ($columnLogId INTEGER PRIMARY KEY AUTOINCREMENT, $columnLogMessage TEXT NOT NULL, $columnLogDirection TEXT NOT NULL, $columnLogTime TEXT NOT NULL)',
          );
          break;
        case 3:
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack0Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack90Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack180Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack0Recv TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack90Recv TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRack180Recv TEXT DEFAULT ""',
          );
          break;
        case 4:
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnLastAngle INTEGER DEFAULT 0',
          );
          break;
        case 5:
          // Add RFID Door Lock scenario columns
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario1Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario1Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario2Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario2Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario3Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario3Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario4Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario4Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidLastMessage TEXT DEFAULT ""',
          );
          // Add Auto Lock Door columns
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnAutoLockCommand TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnAutoLockTimer INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnAutoLockState TEXT DEFAULT "locked"',
          );
          break;
        case 6:
          // Add RFID scenarios 5, 6, and 7
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario5Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario5Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario6Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario6Msg TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario7Cmd TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $tableDevices ADD COLUMN $columnRfidScenario7Msg TEXT DEFAULT ""',
          );
          break;
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Devices table
    await db.execute('''
      CREATE TABLE $tableDevices (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnTab TEXT NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnModel TEXT NOT NULL,
        $columnOnCommand TEXT NOT NULL,
        $columnOffCommand TEXT NOT NULL,
        $columnOnReceive TEXT NOT NULL,
        $columnOffReceive TEXT NOT NULL,
        $columnIcon TEXT NOT NULL,
        $columnIsFavorite INTEGER DEFAULT 0,
        $columnIsOn INTEGER DEFAULT 0,
        $columnOrder INTEGER NOT NULL,
        $columnCreatedAt TEXT NOT NULL,
        $columnRack0Cmd TEXT DEFAULT "",
        $columnRack90Cmd TEXT DEFAULT "",
        $columnRack180Cmd TEXT DEFAULT "",
        $columnRack0Recv TEXT DEFAULT "",
        $columnRack90Recv TEXT DEFAULT "",
        $columnRack180Recv TEXT DEFAULT "",
        $columnLastAngle INTEGER DEFAULT 0,
        $columnRfidScenario1Cmd TEXT DEFAULT "",
        $columnRfidScenario1Msg TEXT DEFAULT "",
        $columnRfidScenario2Cmd TEXT DEFAULT "",
        $columnRfidScenario2Msg TEXT DEFAULT "",
        $columnRfidScenario3Cmd TEXT DEFAULT "",
        $columnRfidScenario3Msg TEXT DEFAULT "",
        $columnRfidScenario4Cmd TEXT DEFAULT "",
        $columnRfidScenario4Msg TEXT DEFAULT "",
        $columnRfidScenario5Cmd TEXT DEFAULT "",
        $columnRfidScenario5Msg TEXT DEFAULT "",
        $columnRfidScenario6Cmd TEXT DEFAULT "",
        $columnRfidScenario6Msg TEXT DEFAULT "",
        $columnRfidScenario7Cmd TEXT DEFAULT "",
        $columnRfidScenario7Msg TEXT DEFAULT "",
        $columnRfidLastMessage TEXT DEFAULT "",
        $columnAutoLockCommand TEXT DEFAULT "",
        $columnAutoLockTimer INTEGER DEFAULT 0,
        $columnAutoLockState TEXT DEFAULT "locked"
      )
    ''');

    // Terminal logs table (for persistent logging)
    await db.execute('''
      CREATE TABLE $tableTerminalLogs (
        $columnLogId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnLogMessage TEXT NOT NULL,
        $columnLogDirection TEXT NOT NULL,
        $columnLogTime TEXT NOT NULL
      )
    ''');
  }

  // Device CRUD Operations

  Future<String> createDevice(SmartDeviceDB device) async {
    final db = await database;
    final id = device.id;
    await db.insert(tableDevices, device.toMap());
    return id;
  }

  Future<SmartDeviceDB?> getDevice(String id) async {
    final db = await database;
    final maps = await db.query(
      tableDevices,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SmartDeviceDB.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SmartDeviceDB>> getAllDevices() async {
    final db = await database;
    final maps = await db.query(tableDevices, orderBy: '$columnOrder ASC');
    return maps.map((map) => SmartDeviceDB.fromMap(map)).toList();
  }

  Future<List<SmartDeviceDB>> getDevicesByTab(String tab) async {
    final db = await database;
    final maps = await db.query(
      tableDevices,
      where: '$columnTab = ?',
      whereArgs: [tab],
      orderBy: '$columnOrder ASC',
    );
    return maps.map((map) => SmartDeviceDB.fromMap(map)).toList();
  }

  Future<List<SmartDeviceDB>> getFavoriteDevices() async {
    final db = await database;
    final maps = await db.query(
      tableDevices,
      where: '$columnIsFavorite = ?',
      whereArgs: [1],
      orderBy: '$columnOrder ASC',
    );
    return maps.map((map) => SmartDeviceDB.fromMap(map)).toList();
  }

  Future<void> updateDevice(SmartDeviceDB device) async {
    final db = await database;
    await db.update(
      tableDevices,
      device.toMap(),
      where: '$columnId = ?',
      whereArgs: [device.id],
    );
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    await db.delete(tableDevices, where: '$columnId = ?', whereArgs: [id]);
  }

  // Reorder devices
  Future<void> reorderDevices(List<SmartDeviceDB> devices) async {
    final db = await database;
    final batch = db.batch();

    for (int i = 0; i < devices.length; i++) {
      final device = devices[i];
      device.order = i;
      batch.update(
        tableDevices,
        device.toMap(),
        where: '$columnId = ?',
        whereArgs: [device.id],
      );
    }

    await batch.commit();
  }

  // Toggle favorite
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      tableDevices,
      {columnIsFavorite: isFavorite ? 1 : 0},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Update device ON/OFF state
  Future<void> updateDeviceState(String id, bool isOn) async {
    final db = await database;
    await db.update(
      tableDevices,
      {columnIsOn: isOn ? 1 : 0},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Update laundry rack angle
  Future<void> updateRackAngle(String id, int angle) async {
    final db = await database;
    await db.update(
      tableDevices,
      {columnLastAngle: angle},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Update RFID last message
  Future<void> updateRfidLastMessage(String id, String message) async {
    final db = await database;
    await db.update(
      tableDevices,
      {columnRfidLastMessage: message},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> getDeviceCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableDevices'),
    );
    return count ?? 0;
  }

  // Terminal log operations
  Future<void> logTerminalEntry(String message, String direction) async {
    final db = await database;
    await db.insert(tableTerminalLogs, {
      columnLogMessage: message,
      columnLogDirection: direction,
      columnLogTime: DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTerminalLogs({int limit = 500}) async {
    final db = await database;
    return await db.query(
      tableTerminalLogs,
      orderBy: '$columnLogTime DESC',
      limit: limit,
    );
  }

  Future<void> clearTerminalLogs() async {
    final db = await database;
    await db.delete(tableTerminalLogs);
  }

  // Database utilities
  Future<void> deleteAllDevices() async {
    final db = await database;
    await db.delete(tableDevices);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableDevices);
    await db.delete(tableTerminalLogs);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
