import 'package:flutter/material.dart';
import '../models/idea.dart';
// import '../models/action.dart'; // 通常のインポートをコメントアウト
import '../models/action.dart' as model; // プレフィックス付きでインポート
import 'dart:math';
import 'package:uuid/uuid.dart';

// モックAPIサービス - Singleton パターンに変更
class ApiService {
  // --- Singleton Implementation Start ---
  // 静的インスタンス (一度だけ生成される)
  static final ApiService _instance = ApiService._internal();

  // 常に同じインスタンスを返すファクトリコンストラクタ
  factory ApiService() {
    return _instance;
  }

  // プライベートな名前付きコンストラクタ (外部からの直接生成を防ぐ)
  ApiService._internal() {
    // インスタンス生成時に一度だけ初期化処理を行う
    print("[ApiService] Singleton instance created and initialized."); // DEBUG PRINT
    _initSampleData();
  }
  // --- Singleton Implementation End ---

  final _uuid = Uuid();
  final List<Idea> _ideas = [];

  // サンプルデータを初期化 (ロジックを簡略化)
  void _initSampleData() {
    _ideas.clear();
    final now = DateTime.now();
    final goalDeadlineOffset = const Duration(days: 7);
    final actionDeadlineOffset = const Duration(hours: 24);

    // === サンプルデータ作成 (Idea を先に作り、Action に確定 ID を使う) ===

    // アイデア1: アクティブ、アクション複数
    final idea1Id = _uuid.v4();
    final idea1Actions = [
      model.Action(id: _uuid.v4(), ideaId: idea1Id, category: model.ActionCategory.marketResearch, note: '競合アプリの調査', createdAt: now.subtract(const Duration(days: 2, hours: 2))),
      model.Action(id: _uuid.v4(), ideaId: idea1Id, category: model.ActionCategory.prototyping, note: '主要画面のデザイン作成', createdAt: now.subtract(const Duration(days: 1, hours: 5))),
    ];
    final idea1 = Idea(
      id: idea1Id, // 確定した ID を使用
      title: 'AIを活用した料理レシピアプリ',
      description: '冷蔵庫にある食材から最適なレシピを提案するアプリ',
      goal: 'MVPリリース',
      createdAt: now.subtract(const Duration(days: 3)),
      expireAt: idea1Actions.last.createdAt.add(actionDeadlineOffset), // 最後のアクションから24時間
      expireGoalAt: now.subtract(const Duration(days: 3)).add(goalDeadlineOffset), // 作成日時から7日
      actions: idea1Actions,
    );
    _ideas.add(idea1); // リストに追加

    // アイデア2: アクティブ、アクション1つ
    final idea2Id = _uuid.v4();
    final idea2Actions = [
      model.Action(id: _uuid.v4(), ideaId: idea2Id, category: model.ActionCategory.userTesting, note: 'ターゲットユーザーへのインタビュー実施', createdAt: now.subtract(const Duration(days: 1))),
    ];
    final idea2 = Idea(
      id: idea2Id,
      title: '位置情報を活用した友達マッチングアプリ',
      description: '近くにいる同じ趣味の人と出会えるアプリ',
      goal: 'ユーザー100人獲得',
      createdAt: now.subtract(const Duration(days: 5)),
      expireAt: idea2Actions.last.createdAt.add(actionDeadlineOffset),
      expireGoalAt: now.subtract(const Duration(days: 5)).add(goalDeadlineOffset),
      actions: idea2Actions,
    );
    _ideas.add(idea2);

    // アイデア3: ゴール達成済み
    final idea3Id = _uuid.v4();
    final idea3Actions = [
      model.Action(id: _uuid.v4(), ideaId: idea3Id, category: model.ActionCategory.prototyping, note: 'β版開発完了', createdAt: now.subtract(const Duration(days: 10))),
      model.Action(id: _uuid.v4(), ideaId: idea3Id, category: model.ActionCategory.goalAchieved, note: '初期ユーザー10名獲得し、公開基準達成', createdAt: now.subtract(const Duration(days: 8))),
    ];
    final idea3 = Idea(
      id: idea3Id,
      title: 'オンラインヨガ教室プラットフォーム',
      description: '自宅で気軽に参加できるライブヨガレッスン',
      goal: '有料会員10人獲得',
      createdAt: now.subtract(const Duration(days: 12)),
      state: IdeaState.published,
      updatedAt: idea3Actions.last.createdAt,
      actions: idea3Actions,
      // expireAt/expireGoalAt は null
    );
    _ideas.add(idea3);

    // アイデア4: アーカイブ済み (期限切れ)
    final idea4Id = _uuid.v4();
    final idea4Actions = [
       model.Action(id: _uuid.v4(), ideaId: idea4Id, category: model.ActionCategory.marketResearch, note: '市場規模の調査', createdAt: now.subtract(const Duration(days: 9))),
    ];
     final idea4 = Idea(
      id: idea4Id,
      title: 'AR家具配置アプリ',
      description: '部屋に家具を配置する前にARで確認できるアプリ',
      goal: '主要家具ブランド連携',
      createdAt: now.subtract(const Duration(days: 15)),
      // expireAt: idea4Actions.last.createdAt.add(actionDeadlineOffset), // アーカイブ済なので不要
      // expireGoalAt: now.subtract(const Duration(days: 15)).add(goalDeadlineOffset), // アーカイブ済なので不要
      state: IdeaState.archived,
      updatedAt: now.subtract(const Duration(days: 8)), // アーカイブ日時
      actions: idea4Actions,
    );
    _ideas.add(idea4);

    // アイデア5: アクティブ、アクションなし (作成直後)
    final idea5Id = _uuid.v4();
    final idea5 = Idea(
      id: idea5Id,
      title: '新しいアイデアの種',
      description: 'これからアクションを追加していくアイデア',
      goal: '最初のプロトタイプ完成',
      createdAt: now.subtract(const Duration(minutes: 30)),
      expireAt: now.subtract(const Duration(minutes: 30)).add(actionDeadlineOffset),
      expireGoalAt: now.subtract(const Duration(minutes: 30)).add(goalDeadlineOffset),
      actions: [],
    );
    _ideas.add(idea5);

    // ID 更新ループは不要になったので削除
    /*
    for (int i = 0; i < _ideas.length; i++) {
      ...
    }
    */
  }

  // アクティブなアイデアを取得 (変更なし)
  Future<List<Idea>> getActiveIdeas() async {
    // 実際のAPIではここでFirestoreからデータを取得
    await Future.delayed(const Duration(milliseconds: 500)); // APIコール遅延をシミュレート
    // タイマーチェックを追加 (本来はバックエンドや定期実行処理で行う)
    _checkAndArchiveIdeas();
    return _ideas.where((idea) => idea.state == IdeaState.active).toList();
  }

  // アーカイブ済みのアイデアを取得 (変更なし)
  Future<List<Idea>> getArchivedIdeas() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _checkAndArchiveIdeas();
    return _ideas.where((idea) => idea.state == IdeaState.archived).toList();
  }

  // 公開済みのアイデアを取得 (メソッド名は変更しないが、意味は「達成済み」)
  Future<List<Idea>> getPublishedIdeas() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _checkAndArchiveIdeas();
    return _ideas.where((idea) => idea.state == IdeaState.published).toList();
  }

  // 特定のアイデアを取得
  Future<Idea?> getIdeaById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // _checkAndArchiveIdeas(); // 削除済み
    print("[ApiService] getIdeaById called for ID: $id"); // DEBUG PRINT
    // ★★★ 追加: 現在のアイデアリストの内容を出力 ★★★
    print("[ApiService] Current ideas in list (${_ideas.length}):");
    for (var ideaInList in _ideas) {
      print("  - ID: ${ideaInList.id}, Title: ${ideaInList.title}, State: ${ideaInList.state}");
    }
    // ★★★ ここまで追加 ★★★
    try {
       final idea = _ideas.firstWhere((idea) => idea.id == id, orElse: () => throw Exception('Not found in firstWhere'));
       print("[ApiService] Idea found for ID: $id"); // DEBUG PRINT
       return idea;
    } catch (e) {
      print("[ApiService] getIdeaById: Exception caught - ${e.toString()}"); // エラー内容も出力
      return null;
    }
  }

  // アイデアを作成 (変更なし)
  Future<Idea> createIdea({
    required String title,
    required String description,
    required String goal,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final actionDeadline = now.add(const Duration(hours: 24));
    final goalDeadline = now.add(const Duration(days: 7));

    final newIdea = Idea(
      id: _uuid.v4(),
      title: title,
      description: description,
      goal: goal,
      createdAt: now,
      expireAt: actionDeadline,
      expireGoalAt: goalDeadline,
      actions: [], // actions を空リストで初期化
    );

    _ideas.add(newIdea);
    return newIdea;
  }

  // アイデアを更新 (シンプル化: updatedAt の更新のみ)
  Future<Idea> updateIdea(Idea idea) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _ideas.indexWhere((i) => i.id == idea.id);
    if (index != -1) {
      // ここでは updatedAt の更新のみを行う
      // 状態やタイマーの更新は addAction や archiveIdea で行う
      _ideas[index] = idea.copyWith(updatedAt: DateTime.now());
      return _ideas[index];
    }
    // 見つからなかった場合のエラーハンドリング (例)
    throw Exception('Idea with id ${idea.id} not found for update');
  }

  // アイデアをアーカイブ (変更なし)
  Future<void> archiveIdea(String ideaId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _ideas.indexWhere((i) => i.id == ideaId);
    if (index != -1) {
      // 既存の archive() メソッドは expireAt/expireGoalAt を null にするのでそのまま使う
      _ideas[index] = _ideas[index].archive();
    }
  }

  // アイデアを削除 (変更なし)
  Future<void> deleteIdea(String ideaId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ideas.removeWhere((idea) => idea.id == ideaId);
  }

  // アクションを追加
  Future<Idea> addAction(String ideaId, model.ActionCategory category, String note) async {
    print("[ApiService] addAction started. Idea ID: $ideaId, Category: ${category.name}"); // DEBUG PRINT
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    final now = DateTime.now();
    final index = _ideas.indexWhere((i) => i.id == ideaId);
    print("[ApiService] Found index: $index"); // DEBUG PRINT

    if (index == -1) {
      print("[ApiService] Error: Idea not found."); // DEBUG PRINT
      throw Exception('Idea with id $ideaId not found');
    }

    final currentIdea = _ideas[index];
    print("[ApiService] Current idea state: ${currentIdea.state}"); // DEBUG PRINT
    if (currentIdea.state != IdeaState.active) {
       print("[ApiService] Error: Cannot add action to non-active idea."); // DEBUG PRINT
       throw Exception('Cannot add action to non-active idea');
    }

    final newAction = model.Action(
      id: _uuid.v4(),
      ideaId: ideaId,
      category: category,
      note: note,
      createdAt: now,
    );
    print("[ApiService] Created new action: ${newAction.id}"); // DEBUG PRINT

    final updatedActions = List<model.Action>.from(currentIdea.actions ?? [])..add(newAction);

    if (category == model.ActionCategory.goalAchieved) {
      print("[ApiService] GoalAchieved action detected. Updating state to published."); // DEBUG PRINT
      final updatedIdea = currentIdea.copyWith(
        actions: updatedActions,
        state: IdeaState.published,
        updatedAt: now,
        setExpireAtNull: true,
        setExpireGoalAtNull: true,
      );
      _ideas[index] = updatedIdea;
      print("[ApiService] Returning published idea."); // DEBUG PRINT
      return updatedIdea;
    } else {
      final newExpireAt = now.add(const Duration(hours: 24));
      print("[ApiService] Normal action. Updating expireAt to: $newExpireAt"); // DEBUG PRINT
      final updatedIdea = currentIdea.copyWith(
        actions: updatedActions,
        expireAt: newExpireAt,
        updatedAt: now,
      );
      _ideas[index] = updatedIdea;
      print("[ApiService] Returning updated active idea."); // DEBUG PRINT
      return updatedIdea;
    }
  }

  // 期限切れチェックとアーカイブ (簡易版、本来は定期実行)
  void _checkAndArchiveIdeas() {
    final now = DateTime.now();
    for (int i = 0; i < _ideas.length; i++) {
      final idea = _ideas[i];
      if (idea.state == IdeaState.active) {
        bool shouldArchive = false;
        // ゴール期限切れチェック
        if (idea.expireGoalAt != null && idea.expireGoalAt!.isBefore(now)) {
          shouldArchive = true;
          print('Archiving idea (goal expired): ${idea.title}');
        }
        // アクション期限切れチェック
        if (!shouldArchive && idea.expireAt != null && idea.expireAt!.isBefore(now)) {
          shouldArchive = true;
          print('Archiving idea (action expired): ${idea.title}');
        }

        if (shouldArchive) {
          _ideas[i] = idea.archive();
        }
      }
    }
  }
}