// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/add_idea_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/api_key_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_screen.dart';
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // Initialize notification service
  await NotificationService().init();
  
  // Initialize subscription service
  await SubscriptionService().init();
  
  // Run the app
  runApp(const LaunchPadApp());
}

class LaunchPadApp extends StatefulWidget {
  const LaunchPadApp({Key? key}) : super(key: key);

  @override
  State<LaunchPadApp> createState() => _LaunchPadAppState();
}

class _LaunchPadAppState extends State<LaunchPadApp> {
  final _authService = AuthService();
  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }
  
  Future<void> _checkAuthState() async {
    try {
      final isLoggedIn = _authService.isLoggedIn;
      
      // Check if user has seen onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      
      setState(() {
        _isLoggedIn = isLoggedIn;
        _hasSeenOnboarding = hasSeenOnboarding;
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      setState(() {
        _initialized = true;
      });
    }
  }
  
  void _listenToAuthChanges() {
    _authService.onAuthStateChange.listen((event) {
      setState(() {
        _isLoggedIn = event.session != null;
        
        // Handle user login/logout in subscription service
        if (_isLoggedIn) {
          SubscriptionService().login(event.session!.user.id);
        } else {
          SubscriptionService().logout();
        }
      });
    });
  }

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
      home: !_initialized
          ? const SplashScreen()
          : _getInitialScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/add_idea': (context) => const AddIdeaScreen(),
        '/steps': (context) => const StepsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/api_key': (context) => const ApiKeyScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms': (context) => const TermsScreen(),
      },
    );
  }
  
  Widget _getInitialScreen() {
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }
    
    if (!_isLoggedIn) {
      return const LoginScreen();
    }
    
    return const HomeScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'LaunchPad Notebook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  bool _isProSubscriber = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check subscription status
      _isProSubscriber = await _subscriptionService.isProSubscriber();
      
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      debugPrint('Error loading settings data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Account section
                _buildSectionHeader('Account'),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  subtitle: Text(_authService.currentUser?.email ?? ''),
                  onTap: () {
                    // Navigate to profile settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Subscription'),
                  subtitle: Text(_isProSubscriber ? 'Pro' : 'Free'),
                  onTap: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                ),
                
                // Preferences section
                _buildSectionHeader('Preferences'),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('API Key Settings'),
                  subtitle: const Text('Configure OpenAI API key'),
                  onTap: () {
                    Navigator.pushNamed(context, '/api_key');
                  },
                ),
                
                // Legal section
                _buildSectionHeader('Legal'),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy_policy');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  onTap: () {
                    Navigator.pushNamed(context, '/terms');
                  },
                ),
                
                // About section
                _buildSectionHeader('About'),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  subtitle: Text(_appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.mail),
                  title: const Text('Contact Support'),
                  onTap: () {
                    // Open email client
                  },
                ),
                
                // Sign out
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// screens/legal/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: DefaultAssetBundle.of(context).loadString('assets/legal/privacy_policy.md'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(data: snapshot.data!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// screens/legal/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: DefaultAssetBundle.of(context).loadString('assets/legal/terms_of_service.md'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(data: snapshot.data!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}