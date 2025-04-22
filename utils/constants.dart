// utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Colors
  static final Color primaryColor = Color(0xFFFF9800);   // Orange
  static final Color progressColor = Color(0xFF4CAF50); // Green
  static final Color dangerColor = Color(0xFFF44336);   // Red
  
  // Timer extensions
  static const Duration captureSaveExtension = Duration(days: 7);
  static const Duration validateAnswerExtension = Duration(hours: 48);
  static const Duration buildTodoExtension = Duration(hours: 24);
}

// models/idea.dart
import 'package:flutter/foundation.dart';

enum IdeaState { active, archived, published }
enum IdeaStep { capture, validate, build, publish }

class Idea {
  final String id;
  final String userId;
  IdeaState state;
  IdeaStep step;
  DateTime expireAt;
  final DateTime createdAt;
  DateTime updatedAt;
  
  // Idea details
  String title;
  String summary;
  Map<String, String>? answers;
  List<Todo>? todos;
  String? platform;
  
  Idea({
    required this.id,
    required this.userId,
    required this.state,
    required this.step,
    required this.expireAt,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.summary,
    this.answers,
    this.todos,
    this.platform,
  });
  
  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      id: json['id'],
      userId: json['user_id'],
      state: IdeaState.values.firstWhere((e) => e.toString().split('.').last == json['state']),
      step: IdeaStep.values.firstWhere((e) => e.toString().split('.').last == json['step']),
      expireAt: DateTime.parse(json['expire_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      title: json['title'],
      summary: json['summary'],
      answers: json['answers'] != null ? Map<String, String>.from(json['answers']) : null,
      todos: json['todos'] != null 
          ? (json['todos'] as List).map((todo) => Todo.fromJson(todo)).toList() 
          : null,
      platform: json['platform'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'state': state.toString().split('.').last,
      'step': step.toString().split('.').last,
      'expire_at': expireAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
      'summary': summary,
      'answers': answers,
      'todos': todos?.map((todo) => todo.toJson()).toList(),
      'platform': platform,
    };
  }
  
  Duration get remainingTime => expireAt.difference(DateTime.now());
  
  bool get isExpired => remainingTime.isNegative;
  
  Color get timerColor {
    final percentage = remainingTime.inHours / (7 * 24);
    if (percentage > 0.66) return AppConstants.progressColor;
    if (percentage > 0.33) return AppConstants.primaryColor;
    return AppConstants.dangerColor;
  }
  
  void extendDeadline(Duration extension) {
    expireAt = expireAt.add(extension);
    updatedAt = DateTime.now();
  }
}

// models/todo.dart
class Todo {
  final String id;
  final String text;
  bool done;
  
  Todo({required this.id, required this.text, this.done = false});
  
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      text: json['text'],
      done: json['done'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'done': done,
    };
  }
}

// services/api_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/idea.dart';
import '../models/todo.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();
  
  // GPT API Key - in a real app, this would be on the server
  final String _openaiApiKey = 'YOUR_OPENAI_API_KEY';
  
  // Create a new idea
  Future<Idea> createIdea(String title, String summary) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final expireAt = now.add(AppConstants.captureSaveExtension);
    
    final ideaId = _uuid.v4();
    
    await _supabase.from('ideas').insert({
      'id': ideaId,
      'user_id': userId,
      'state': 'active',
      'step': 'capture',
      'expire_at': expireAt.toIso8601String(),
    });
    
    await _supabase.from('idea_details').insert({
      'idea_id': ideaId,
      'summary': summary,
    });
    
    return Idea(
      id: ideaId,
      userId: userId,
      state: IdeaState.active,
      step: IdeaStep.capture,
      expireAt: expireAt,
      createdAt: now,
      updatedAt: now,
      title: title,
      summary: summary,
    );
  }
  
  // Get all active ideas
  Future<List<Idea>> getActiveIdeas() async {
    final userId = _supabase.auth.currentUser!.id;
    
    final ideas = await _supabase
        .from('ideas')
        .select('*, idea_details(*)')
        .eq('user_id', userId)
        .eq('state', 'active')
        .order('expire_at');
    
    return ideas.map<Idea>((data) {
      final details = data['idea_details'][0];
      return Idea(
        id: data['id'],
        userId: data['user_id'],
        state: IdeaState.values.firstWhere((e) => e.toString().split('.').last == data['state']),
        step: IdeaStep.values.firstWhere((e) => e.toString().split('.').last == data['step']),
        expireAt: DateTime.parse(data['expire_at']),
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: DateTime.parse(data['updated_at']),
        title: details['title'],
        summary: details['summary'],
        answers: details['answers'] != null ? Map<String, String>.from(details['answers']) : null,
        todos: details['todos'] != null 
            ? (details['todos'] as List).map((todo) => Todo.fromJson(todo)).toList() 
            : null,
        platform: details['platform'],
      );
    }).toList();
  }
  
  // Save validation answers
  Future<void> saveAnswers(String ideaId, Map<String, String> answers) async {
    final idea = await _getIdea(ideaId);
    
    // Update step to validate if it's in capture
    if (idea.step == IdeaStep.capture) {
      await _supabase.from('ideas').update({
        'step': 'validate',
        'expire_at': idea.expireAt.add(AppConstants.validateAnswerExtension).toIso8601String(),
      }).eq('id', ideaId);
    } else {
      // Extend deadline by 48 hours
      await _supabase.from('ideas').update({
        'expire_at': idea.expireAt.add(AppConstants.validateAnswerExtension).toIso8601String(),
      }).eq('id', ideaId);
    }
    
    await _supabase.from('idea_details').update({
      'answers': answers,
    }).eq('idea_id', ideaId);
  }
  
  // Generate todo suggestions using GPT
  Future<List<Todo>> generateTodos(String ideaId) async {
    final idea = await _getIdea(ideaId);
    
    // Generate todos using GPT
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a senior product coach. Split the following idea into a maximum of 5 tasks (each doable within 30 minutes). Return JSON array with {id, text}.'
          },
          {
            'role': 'user',
            'content': '{"title": "${idea.title}", "summary": "${idea.summary}"}'
          }
        ],
        'temperature': 0.7,
      }),
    );
    
    final data = jsonDecode(response.body);
    final todoContent = data['choices'][0]['message']['content'];
    final todoList = jsonDecode(todoContent) as List;
    
    final todos = todoList.map<Todo>((todo) => Todo(
      id: todo['id'] ?? _uuid.v4(),
      text: todo['text'],
    )).toList();
    
    // Update step to build if it's in validate
    if (idea.step == IdeaStep.validate) {
      await _supabase.from('ideas').update({
        'step': 'build',
      }).eq('id', ideaId);
    }
    
    // Save todos to database
    await _supabase.from('idea_details').update({
      'todos': todos.map((todo) => todo.toJson()).toList(),
    }).eq('idea_id', ideaId);
    
    return todos;
  }
  
  // Update todo status
  Future<void> updateTodo(String ideaId, String todoId, bool done) async {
    final idea = await _getIdea(ideaId);
    
    final todos = idea.todos?.map((todo) {
      if (todo.id == todoId) {
        return Todo(id: todo.id, text: todo.text, done: done);
      }
      return todo;
    }).toList();
    
    // Extend deadline if marking as done
    if (done) {
      await _supabase.from('ideas').update({
        'expire_at': idea.expireAt.add(AppConstants.buildTodoExtension).toIso8601String(),
      }).eq('id', ideaId);
    }
    
    await _supabase.from('idea_details').update({
      'todos': todos?.map((todo) => todo.toJson()).toList(),
    }).eq('idea_id', ideaId);
  }
  
  // Publish idea
  Future<void> publishIdea(String ideaId, String platform) async {
    await _supabase.from('ideas').update({
      'state': 'published',
      'step': 'publish',
    }).eq('id', ideaId);
    
    await _supabase.from('idea_details').update({
      'platform': platform,
    }).eq('idea_id', ideaId);
  }
  
  // Archive idea
  Future<void> archiveIdea(String ideaId) async {
    await _supabase.from('ideas').update({
      'state': 'archived',
    }).eq('id', ideaId);
  }
  
  // Extend idea deadline by 24 hours
  Future<void> extendDeadline(String ideaId) async {
    final idea = await _getIdea(ideaId);
    
    await _supabase.from('ideas').update({
      'expire_at': idea.expireAt.add(const Duration(hours: 24)).toIso8601String(),
    }).eq('id', ideaId);
  }
  
  // Helper method to get idea
  Future<Idea> _getIdea(String ideaId) async {
    final response = await _supabase
        .from('ideas')
        .select('*, idea_details(*)')
        .eq('id', ideaId)
        .single();
    
    final details = response['idea_details'][0];
    
    return Idea(
      id: response['id'],
      userId: response['user_id'],
      state: IdeaState.values.firstWhere((e) => e.toString().split('.').last == response['state']),
      step: IdeaStep.values.firstWhere((e) => e.toString().split('.').last == response['step']),
      expireAt: DateTime.parse(response['expire_at']),
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
      title: details['title'],
      summary: details['summary'],
      answers: details['answers'] != null ? Map<String, String>.from(details['answers']) : null,
      todos: details['todos'] != null 
          ? (details['todos'] as List).map((todo) => Todo.fromJson(todo)).toList() 
          : null,
      platform: details['platform'],
    );
  }
  
  // Generate validation answer suggestions using GPT
  Future<List<String>> generateValidationAnswers() async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'Generate concise example answers (≤50 chars JP) for: 1) Target User, 2) Main Problem, 3) Existing alternatives. Return as array order=1..3.'
          }
        ],
        'temperature': 0.7,
      }),
    );
    
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    final answers = jsonDecode(content) as List;
    
    return answers.map<String>((answer) => answer.toString()).toList();
  }
}
