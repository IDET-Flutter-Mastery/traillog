import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/trail_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('trailsBox');

  runApp(const TrailLogApp());
}

class TrailLogApp extends StatelessWidget {
  const TrailLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const TrailListScreen(),
    );
  }
}
