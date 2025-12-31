import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/storage_keys.dart';

class HiveStorage {
  static Box<dynamic>? _box;

  static Future<void> ensureInitialized() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(StorageKeys.box);
  }

  static Box<dynamic> get box => _box!;
}
