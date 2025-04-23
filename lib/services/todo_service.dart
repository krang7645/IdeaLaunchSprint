import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';

/// タスク（Todo）を管理するサービス
class TodoService {
  final _uuid = Uuid();
  final List<Todo> _todos = [];

  // 新しいタスクを作成
  Future<Todo?> createTodo({
    required String ideaId,
    required String title,
    DateTime? dueDate,
  }) async {
    // API呼び出しの遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 300));

    final newTodo = Todo(
      id: _uuid.v4(),
      ideaId: ideaId,
      title: title,
      done: false,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    _todos.add(newTodo);
    return newTodo;
  }

  // タスクの状態を切り替え（完了⇔未完了）
  Future<Todo?> toggleTodoStatus(String todoId) async {
    // API呼び出しの遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 200));

    final todo = _todos.firstWhere(
      (todo) => todo.id == todoId,
      orElse: () => throw Exception('タスクが見つかりません'),
    );

    final updatedTodo = todo.copyWith(
      done: !todo.done,
      completedAt: !todo.done ? DateTime.now() : null,
    );

    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      _todos[index] = updatedTodo;
    }

    return updatedTodo;
  }

  // タスクを削除
  Future<bool> deleteTodo(String todoId) async {
    // API呼び出しの遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 200));

    final initialLength = _todos.length;
    _todos.removeWhere((todo) => todo.id == todoId);
    return _todos.length < initialLength;
  }

  // 特定のアイデアに関連するタスクを取得
  Future<List<Todo>> getTodosByIdeaId(String ideaId) async {
    // API呼び出しの遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 200));

    return _todos.where((todo) => todo.ideaId == ideaId).toList();
  }

  // ランダムなサンプルタスクを生成（デモ用）
  List<Todo> generateSampleTodos(String ideaId, int count) {
    final now = DateTime.now();
    final random = Random();

    final sampleTasks = [
      'デザインプロトタイプを作成',
      'マーケットリサーチを実施',
      'ユーザーインタビューを実施',
      'コンペティター分析を行う',
      'ビジネスモデルを検討',
      'サービス仕様書を作成',
      'プレゼンテーション資料を作成',
      'テスト計画を立てる',
      'フィードバックを収集',
      'SNS戦略を立てる',
      'ブランディング要素を検討',
      'パートナー企業にコンタクト',
      'プロジェクト予算を確認',
      'チームメンバーを募集',
    ];

    return List.generate(
      count,
      (index) {
        final title = sampleTasks[random.nextInt(sampleTasks.length)];
        final isDone = random.nextBool() && random.nextBool(); // 25%の確率で完了状態に
        final hasDueDate = random.nextBool();

        return Todo(
          id: _uuid.v4(),
          ideaId: ideaId,
          title: '$title ${index + 1}',
          done: isDone,
          completedAt: isDone ? now.subtract(Duration(hours: random.nextInt(48))) : null,
          dueDate: hasDueDate ? now.add(Duration(days: random.nextInt(14) + 1)) : null,
          createdAt: now.subtract(Duration(days: random.nextInt(7))),
        );
      },
    );
  }
}