import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/database/connection/open_connection.dart';

/// Marker file in the documents folder: present while demo mode is on.
const String demoMarkerFileName = 'auditor_monkey_demo.on';

/// The demo file, its SQLite side files and the marker, in one folder.
/// Never touches the real database file.
class DemoFiles {
  const DemoFiles(this.dir);

  final Directory dir;

  File get _marker => File(p.join(dir.path, demoMarkerFileName));

  List<File> get _databaseFiles => <File>[
    for (final String suffix in const <String>['', '-wal', '-shm', '-journal'])
      File(p.join(dir.path, '$demoDatabaseFileName$suffix')),
  ];

  bool get markerExists => _marker.existsSync();

  Future<void> writeMarker() => _marker.writeAsString('demo');

  Future<void> deleteMarker() async {
    if (_marker.existsSync()) await _marker.delete();
  }

  Future<void> deleteDatabase() async {
    for (final File f in _databaseFiles) {
      if (f.existsSync()) await f.delete();
    }
  }
}

/// Reads the marker once at start (before the first frame).
Future<bool> readDemoMarker([DatabaseDirectory? directory]) async {
  final Directory dir = await (directory ?? defaultDatabaseDirectory)();
  return DemoFiles(dir).markerExists;
}
