import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart'; // Material Icons のために追加

// アクションカテゴリの定義
enum ActionCategory {
  marketResearch('市場調査', Icons.search),
  prototyping('プロトタイプ開発', Icons.build),
  userTesting('ユーザーテスト', Icons.person_search),
  marketing('マーケティング', Icons.campaign),
  releasePrep('リリース準備', Icons.settings),
  goalAchieved('ゴール達成', Icons.flag), // 公開 -> ゴール達成 に変更
  other('その他', Icons.more_horiz);

  const ActionCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

@immutable
class Action {
  final String id;
  final String ideaId;
  final ActionCategory category;
  final String note;
  final DateTime createdAt;

  const Action({
    required this.id,
    required this.ideaId,
    required this.category,
    required this.note,
    required this.createdAt,
  });

  // 必要に応じて fromJson, toJson, copyWith を追加
  // (今回はローカルのみなので必須ではないが、将来的な拡張性を考慮すると良い)

  Action copyWith({
    String? id,
    String? ideaId,
    ActionCategory? category,
    String? note,
    DateTime? createdAt,
  }) {
    return Action(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

   @override
  String toString() {
    return 'Action(id: $id, ideaId: $ideaId, category: ${category.name}, note: $note, createdAt: $createdAt)';
  }
}