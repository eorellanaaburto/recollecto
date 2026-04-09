import 'package:flutter/material.dart';
import 'package:recollecto/features/home/presentation/homepage.dart';

import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.loadTheme();
  await LocaleController.instance.loadLocale();
  runApp(const RecollectoApp());
}

class CollectorApp extends StatelessWidget {
  const CollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collector App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashLauncher(),
    );
  }
}

class SplashLauncher extends StatefulWidget {
  const SplashLauncher({super.key});

  @override
  State<SplashLauncher> createState() => _SplashLauncherState();
}

class _SplashLauncherState extends State<SplashLauncher> {
  @override
  void initState() {
    super.initState();
    _goToHome();
  }

  Future<void> _goToHome() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 160, height: 160),
            const SizedBox(height: 24),
            const Text(
              'Collector App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Organiza y respalda tu colección',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
