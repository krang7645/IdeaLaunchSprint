// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/add_idea_screen.dart';
import 'screens/steps_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  runApp(const LaunchPadApp());
}

class LaunchPadApp extends StatelessWidget {
  const LaunchPadApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaunchPad Notebook',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.progressColor,
          error: AppConstants.dangerColor,
        ),
        fontFamily: 'SFPro',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/add_idea': (context) => const AddIdeaScreen(),
        '/steps': (context) => const StepsScreen(),
      },
    );
  }
}
