import 'package:flutter/material.dart';
// import 'todo.dart'; // Todo を削除し、Action をインポート
import 'action.dart' as model; // プレフィックス付きでインポート

enum IdeaState {
  active,
  archived,
  published, // ゴール達成済みの意味合いに変更
}

// IdeaStep enum を削除
// enum IdeaStep {
//   capture,
//   validate,
//   build,
//   publish,
// }

class Idea {
  final String id;
  final String title;
  final String description;
  final String goal;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expireAt; // 最後のアクションから24時間
  final DateTime? expireGoalAt; // 作成から7日間
  final IdeaState state;
  // final IdeaStep step; // 削除
  // final Map<String, String>? validateAnswers; // 削除
  // final List<Todo>? todos; // 削除
  // final String? publishPlatform; // 削除
  final List<model.Action>? actions; // 型を model.Action に変更

  Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.goal, // ゴールは維持
    required this.createdAt,
    this.updatedAt,
    this.expireAt,
    this.expireGoalAt,
    this.state = IdeaState.active,
    // this.step = IdeaStep.capture, // 削除
    // this.validateAnswers, // 削除
    // this.todos, // 削除
    // this.publishPlatform, // 削除
    this.actions, // 追加
  });

  // currentStep getter を削除
  // int get currentStep => step.index;

  // 残り時間 (アクション期限) を計算
  int get remainingDays {
    if (expireAt == null || state != IdeaState.active) return 0;
    final diff = expireAt!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  int get remainingHours {
    if (expireAt == null || state != IdeaState.active) return 0;
    final diff = expireAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inHours % 24;
  }

  // 残りゴール日数を計算 (作成からの期限)
  int get remainingGoalDays {
    if (expireGoalAt == null || state != IdeaState.active) return 0;
    final diff = expireGoalAt!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  // getStepProgress を削除
  // double getStepProgress() { ... }

  // アイデアをアーカイブする (変更なし)
  Idea archive() {
    return copyWith(
      state: IdeaState.archived,
      updatedAt: DateTime.now(),
      expireAt: null, // アーカイブ時はタイマー無効化
      expireGoalAt: null,
    );
  }

  // publish メソッドを削除
  // Idea publish() { ... }

  // extendActionDeadline メソッドを削除
  // Idea extendActionDeadline(Duration duration) { ... }

  Idea copyWith({
    String? id,
    String? title,
    String? description,
    String? goal,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expireAt,
    DateTime? expireGoalAt,
    IdeaState? state,
    // IdeaStep? step, // 削除
    // Map<String, String>? validateAnswers, // 削除
    // List<Todo>? todos, // 削除
    // String? publishPlatform, // 削除
    List<model.Action>? actions, // 型を model.Action に変更
    bool setExpireAtNull = false, // expireAt を null に設定するフラグ
    bool setExpireGoalAtNull = false, // expireGoalAt を null に設定するフラグ
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expireAt: setExpireAtNull ? null : (expireAt ?? this.expireAt),
      expireGoalAt: setExpireGoalAtNull ? null : (expireGoalAt ?? this.expireGoalAt),
      state: state ?? this.state,
      // step: step ?? this.step, // 削除
      // validateAnswers: validateAnswers ?? this.validateAnswers, // 削除
      // todos: todos ?? this.todos, // 削除
      // publishPlatform: publishPlatform ?? this.publishPlatform, // 削除
      actions: actions ?? this.actions, // 追加
    );
  }

  @override
  String toString() {
    // return 'Idea(id: $id, title: $title, goal: $goal, step: $step, state: $state)'; // 修正
    return 'Idea(id: $id, title: $title, goal: $goal, state: $state, actions: ${actions?.length ?? 0})';
  }
}