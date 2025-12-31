import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/storage_keys.dart';
import '../models/app_state.dart';
import '../storage/hive_storage.dart';

class AppRepository {
  Future<AppStateModel> load() async {
    final raw = HiveStorage.box.get(StorageKeys.state);
    if (raw == null) {
      return AppStateModel();
    }
    return AppStateModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> save(AppStateModel state) async {
    await HiveStorage.box.put(StorageKeys.state, state.toJson());
  }

  Future<void> reset() async {
    await HiveStorage.box.delete(StorageKeys.state);
  }

  Future<String> exportJson(AppStateModel state) async {
    final jsonStr = jsonEncode(state.toJson());
    if (kIsWeb) {
      return jsonStr;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/close_the_ramp.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Close the Ramp export');
    return jsonStr;
  }

  Future<AppStateModel?> importJson() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
        if (result != null && result.files.single.bytes != null) {
          final content = utf8.decode(result.files.single.bytes!);
          return AppStateModel.fromJson(jsonDecode(content) as Map<String, dynamic>);
        }
      } else {
        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final content = await file.readAsString();
          return AppStateModel.fromJson(jsonDecode(content) as Map<String, dynamic>);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
