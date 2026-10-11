import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'services/player_service.dart';
import 'services/download_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/snackbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();

  // Playback diagnostics: route youtube_explode's internal logs (which client
  // failed and why) into the debug console instead of swallowing them.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    debugPrint('[yt] ${r.loggerName}: ${r.message}'
        '${r.error != null ? ' | error: ${r.error}' : ''}');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
      ],
      child: const CapuTuneApp(),
    ),
  );
}

class CapuTuneApp extends StatelessWidget {
  const CapuTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, playerService, child) {
        return MaterialApp(
          title: 'Capu Tune',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: playerService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
