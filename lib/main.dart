import 'dart:async';

import 'package:flutter/material.dart';

import 'config.dart';
import 'db.dart';
import 'home.dart';
import 'questions.dart';
import 'simulado.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance.init();
  runApp(const ConcursaApp());
}

class ConcursaApp extends StatelessWidget {
  const ConcursaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concursa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lime,
          brightness: Brightness.dark,
          surface: cardColor,
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: bgColor,
          indicatorColor: lime.withValues(alpha: .22),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                border: Border.all(color: lime, width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.school, color: lime, size: 72),
            ),
            const SizedBox(height: 22),
            const Text(
              'Concursa',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seu estudo, seu futuro!',
              style: TextStyle(color: lime, fontSize: 16),
            ),
            const SizedBox(height: 26),
            const Text(
              'Questões · Simulados · Resultados',
              style: TextStyle(color: dimText),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(color: lime, backgroundColor: cardColor),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  int gen = 0;

  void go(int t) {
    setState(() {
      tab = t;
      gen++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onTab: go),
      const SubjectsScreen(),
      const QuestionsScreen(),
      const SimuladoScreen(),
      const ConfigScreen(),
    ];
    return Scaffold(
      body: KeyedSubtree(key: ValueKey('$tab-$gen'), child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Estudar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Questões',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Simulados',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config.',
          ),
        ],
      ),
    );
  }
}
