// main.dart
// import 'dart:async'; // 不要に
import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // 不要に
import 'screens/home_screen.dart';
// import 'screens/auth_screen.dart'; // 不要に

void main() /*async*/ { // async を削除
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 初期化を削除
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );
  // print("Supabase initialized");

  runApp(const MyApp());
}

// final supabase = Supabase.instance.client; // 不要に

// StatefulWidget から StatelessWidget に戻す
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // print("[MyApp] build: ..."); // デバッグプリント削除
    return MaterialApp(
      title: 'アイデアランチャー',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 常に HomeScreen を表示
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// _MyAppState クラス全体を削除
// class _MyAppState extends State<MyApp> {
//   ...
// }