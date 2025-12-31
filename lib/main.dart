import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/storage/hive_storage.dart';
import 'features/emergency/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: CloseTheRampApp()));
}
