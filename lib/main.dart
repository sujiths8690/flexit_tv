import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow all orientations — orientation is set dynamically from server
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FlexitApp());
}

class FlexitApp extends StatelessWidget {
  const FlexitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flexit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
