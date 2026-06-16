import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trace_ar.db');
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

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const nullableText = 'TEXT';

    await db.execute('''
CREATE TABLE projects (
  id $textType PRIMARY KEY,
  name $textType,
  localImagePath $textType,
  cloudImageUrl $nullableText,
  widthCm $realType,
  heightCm $realType,
  opacity $realType,
  rotation $realType,
  flipX $integerType,
  flipY $integerType,
  isLocked $integerType,
  gridEnabled $integerType,
  gridSize $integerType,
  createdAt $integerType,
  updatedAt $integerType,
  isSynced $integerType
)
''');
  }

  // Create Project
  Future<Project> createProject(Project project) async {
    final db = await instance.database;
    await db.insert('projects', project.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return project;
  }

  // Get single project
  Future<Project?> getProject(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'projects',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Project.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = await instance.database;
    final result = await db.query('projects', orderBy: 'createdAt DESC');
    return result.map((json) => Project.fromMap(json)).toList();
  }

  // Update project
  Future<int> updateProject(Project project) async {
    final db = await instance.database;
    return db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  // Duplicate Project
  Future<Project> duplicateProject(Project project, String newName) async {
    final duplicated = Project(
      id: const Uuid().v4(),
      name: newName,
      localImagePath: project.localImagePath,
      cloudImageUrl: null,
      widthCm: project.widthCm,
      heightCm: project.heightCm,
      opacity: project.opacity,
      rotation: project.rotation,
      flipX: project.flipX,
      flipY: project.flipY,
      isLocked: project.isLocked,
      gridEnabled: project.gridEnabled,
      gridSize: project.gridSize,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isSynced: false,
    );
    await createProject(duplicated);
    return duplicated;
  }

  // Delete project
  Future<int> deleteProject(String id) async {
    final db = await instance.database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get unsynced projects
  Future<List<Project>> getUnsyncedProjects() async {
    final db = await instance.database;
    final result = await db.query(
      'projects',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((json) => Project.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
