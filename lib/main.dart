import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatgpt_sample/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .evnから環境変数を読み込む
  await dotenv.load(fileName: '.env');
  OpenAI.apiKey = dotenv.get('OPEN_AI_API_KEY');

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Sample',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF52c41a),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF52c41a),
      ),
      home: const HomeScreen(),
    );
  }
}
