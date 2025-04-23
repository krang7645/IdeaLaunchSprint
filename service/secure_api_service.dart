// services/secure_api_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureApiService {
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  
  // API key constants
  static const String _openAiKeyName = 'openai_api_key';
  
  // Base URLs
  static const String _openAiBaseUrl = 'https://api.openai.com/v1';
  
  // Server proxy endpoint (to be implemented in a secure backend)
  static const String _serverProxyUrl = 'https://api.launchpad-notebook.com/proxy';

  // Check if we're using secure mode (server-side API key handling)
  Future<bool> get _isSecureMode async {
    // In a real app, this would be determined by subscription status or app settings
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userProfile = await _supabase.from('profiles').select().eq('id', user.id).single();
      return userProfile['subscription_tier'] == 'pro';
    }
    return false;
  }

  // Set OpenAI API key (for non-secure mode)
  Future<void> setOpenAIApiKey(String apiKey) async {
    await _secureStorage.write(key: _openAiKeyName, value: apiKey);
  }

  // Get OpenAI API key (for non-secure mode)
  Future<String?> getOpenAIApiKey() async {
    return await _secureStorage.read(key: _openAiKeyName);
  }

  // Delete OpenAI API key
  Future<void> deleteOpenAIApiKey() async {
    await _secureStorage.delete(key: _openAiKeyName);
  }

  // Make a secure API call to OpenAI
  Future<Map<String, dynamic>> callOpenAI({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final isSecure = await _isSecureMode;
    
    if (isSecure) {
      // Use server-side proxy for API calls (more secure)
      return await _callOpenAISecure(endpoint, body);
    } else {
      // Use client-side API key (less secure, but works for free tier)
      return await _callOpenAIDirect(endpoint, body);
    }
  }

  // Make a direct call to OpenAI API (less secure, client-side key)
  Future<Map<String, dynamic>> _callOpenAIDirect(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final apiKey = await getOpenAIApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found. Please set your API key in the settings.');
    }
    
    final response = await http.post(
      Uri.parse('$_openAiBaseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to call OpenAI API: ${response.body}');
    }
  }

  // Make a secure call to OpenAI via server proxy (more secure, server-side key)
  Future<Map<String, dynamic>> _callOpenAISecure(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.post(
      Uri.parse('$_serverProxyUrl/openai/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${user.id}',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to call OpenAI API via proxy: ${response.body}');
    }
  }

  // Generate validation answers using GPT (secure)
  Future<List<String>> generateValidationAnswers() async {
    final response = await callOpenAI(
      endpoint: 'chat/completions',
      body: {
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'Generate concise example answers (≤50 chars JP) for: 1) Target User, 2) Main Problem, 3) Existing alternatives. Return as array order=1..3.'
          }
        ],
        'temperature': 0.7,
      },
    );
    
    final content = response['choices'][0]['message']['content'];
    final answers = jsonDecode(content) as List;
    
    return answers.map<String>((answer) => answer.toString()).toList();
  }

  // Generate todo suggestions using GPT (secure)
  Future<List<Map<String, dynamic>>> generateTodos(String title, String summary) async {
    final response = await callOpenAI(
      endpoint: 'chat/completions',
      body: {
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a senior product coach. Split the following idea into a maximum of 5 tasks (each doable within 30 minutes). Return JSON array with {id, text}.'
          },
          {
            'role': 'user',
            'content': '{"title": "$title", "summary": "$summary"}'
          }
        ],
        'temperature': 0.7,
      },
    );
    
    final content = response['choices'][0]['message']['content'];
    return List<Map<String, dynamic>>.from(jsonDecode(content));
  }
}

// screens/settings/api_key_screen.dart
import 'package:flutter/material.dart';
import '../../services/secure_api_service.dart';
import '../../utils/constants.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({Key? key}) : super(key: key);

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _secureApiService = SecureApiService();
  bool _isLoading = false;
  bool _hasApiKey = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiKey = await _secureApiService.getOpenAIApiKey();
      setState(() {
        _hasApiKey = apiKey != null && apiKey.isNotEmpty;
        if (_hasApiKey) {
          _apiKeyController.text = apiKey!;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking API key: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _secureApiService.setOpenAIApiKey(_apiKeyController.text.trim());
        setState(() {
          _hasApiKey = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving API key: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeApiKey() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove API Key'),
          content: const Text(
              'Are you sure you want to remove your OpenAI API key?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await _secureApiService.deleteOpenAIApiKey();
                  setState(() {
                    _hasApiKey = false;
                    _apiKeyController.clear();
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('API key removed successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error removing API key: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Remove'),
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
        title: const Text('API Key Settings'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OpenAI API Key',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'LaunchPad Notebook uses OpenAI\'s GPT models to provide AI-powered features. Enter your API key below to enable these features.',
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        labelText: 'OpenAI API Key',
                        hintText: 'sk-...',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureKey
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureKey = !_obscureKey;
                                });
                              },
                            ),
                            if (_hasApiKey)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _removeApiKey,
                              ),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your API key';
                        }
                        if (!value.startsWith('sk-')) {
                          return 'API key should start with sk-';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Save API Key'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'How to get an OpenAI API key:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Go to openai.com and create an account',
                  ),
                  const Text(
                    '2. Navigate to the API section',
                  ),
                  const Text(
                    '3. Create a new API key',
                  ),
                  const Text(
                    '4. Copy and paste the key here',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: Your API key is stored securely on your device only. API usage will be charged to your OpenAI account.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'With a Pro subscription, you\'ll no longer need to provide your own API key. All AI features will be included in your subscription.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to subscription screen
                      Navigator.pushNamed(context, '/subscription');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('View Subscription Plans'),
                  ),
                ],
              ),
            ),
    );
  }
}

// services/proxy_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class ProxyService {
  static final ProxyService _instance = ProxyService._internal();
  factory ProxyService() => _instance;
  ProxyService._internal();

  final String _backendUrl = AppConstants.backendUrl;

  // Health check
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Proxy a GPT chat completion request
  Future<Map<String, dynamic>> proxyGptChat({
    required String authToken,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/openai/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'messages': messages,
        'temperature': temperature,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to call proxy API: ${response.body}');
    }
  }

  // Get validation answers via proxy
  Future<List<String>> getValidationAnswers(String authToken) async {
    final messages = [
      {
        'role': 'system',
        'content': 'Generate concise example answers (≤50 chars JP) for: 1) Target User, 2) Main Problem, 3) Existing alternatives. Return as array order=1..3.'
      }
    ];

    final response = await proxyGptChat(
      authToken: authToken,
      messages: messages,
    );

    final content = response['choices'][0]['message']['content'];
    final answers = jsonDecode(content) as List;
    
    return answers.map<String>((answer) => answer.toString()).toList();
  }

  // Generate todos via proxy
  Future<List<Map<String, dynamic>>> generateTodos({
    required String authToken,
    required String title,
    required String summary,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': 'You are a senior product coach. Split the following idea into a maximum of 5 tasks (each doable within 30 minutes). Return JSON array with {id, text}.'
      },
      {
        'role': 'user',
        'content': '{"title": "$title", "summary": "$summary"}'
      }
    ];

    final response = await proxyGptChat(
      authToken: authToken,
      messages: messages,
    );

    final content = response['choices'][0]['message']['content'];
    return List<Map<String, dynamic>>.from(jsonDecode(content));
  }
}