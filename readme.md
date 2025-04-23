# LaunchPad Notebook

> "思いつきを最速でリリースする文化を創る"

LaunchPad Notebook は、アイデアを最速でリリースするための完全なフレームワークを提供するアプリです。捕捉（Capture）、検証（Validate）、構築（Build）、公開（Publish）の4つのステップで、あなたのアイデアを具体的な成果物へと変えます。

## 🚀 特徴

- **タイマー駆動型ワークフロー**: アイデアにはすべて7日間の期限があり、行動することで延命されます
- **AI支援の検証**: GPTがアイデアの検証をサポートします
- **自動To-Do生成**: GPTがアイデアを実行可能なタスクに分解します
- **公開支援**: 主要プラットフォームへの公開をガイドします

## 📋 プロジェクト構造

```
lib/
  ├── main.dart             # アプリケーションエントリーポイント
  ├── models/               # データモデル
  │   ├── idea.dart         # アイデアモデル
  │   └── todo.dart         # Todoモデル
  ├── screens/              # UI画面
  │   ├── home_screen.dart  # ホーム画面（インボックス）
  │   ├── add_idea_screen.dart  # アイデア追加画面
  │   └── steps_screen.dart     # ステップ表示画面
  ├── services/             # サービス
  │   └── api_service.dart  # APIサービス（Supabase連携）
  ├── utils/                # ユーティリティ
  │   └── constants.dart    # 定数
  └── widgets/              # 再利用可能なUIコンポーネント
      ├── idea_card.dart    # アイデアカード
      ├── capture_step.dart # キャプチャステップ
      ├── validate_step.dart # 検証ステップ
      ├── build_step.dart   # 構築ステップ
      └── publish_step.dart # 公開ステップ
```

## 🔧 セットアップ

### 前提条件

- Flutter SDK (3.0.0以上)
- Supabase アカウント
- OpenAI API キー

### インストール

1. リポジトリをクローン:
   ```bash
   git clone https://github.com/yourusername/launchpad_notebook.git
   cd launchpad_notebook
   ```

2. 依存関係をインストール:
   ```bash
   flutter pub get
   ```

3. Supabaseプロジェクトを作成:
   - Supabase管理コンソールからプロジェクトを作成
   - SQLエディタを開き、`supabase/schema.sql`のSQLスクリプトを実行

4. 環境変数を設定:
   - `lib/utils/constants.dart`を編集し、以下の値を設定:
     - `supabaseUrl`: SupabaseプロジェクトのURL
     - `supabaseAnonKey`: Supabaseの匿名キー
     - `services/api_service.dart`で`_openaiApiKey`を設定

5. アプリを実行:
   ```bash
   flutter run
   ```

## 💻 使用方法

1. **ホーム画面**:
   - アクティブなアイデアの一覧が表示されます
   - 左スワイプで24時間延長、右スワイプでアーカイブできます
   - フローティングアクションボタンからアイデアを追加できます

2. **アイデア追加**:
   - タイトルと概要（最大140文字）を入力し、保存ボタンでスタート
   - 保存すると7日間のタイマーがスタートします

3. **ステップ画面**:
   - **Capture**: アイデアの基本情報を表示
   - **Validate**: 3つの質問に回答し、アイデアを検証（回答ごとに+48時間）
   - **Build**: AIがTo-Doリストを生成し、タスクを完了（タスク完了ごとに+24時間）
   - **Publish**: プラットフォームを選択し公開

## 📱 画面

- **ホーム画面**: アイデアのリスト
- **アイデア追加画面**: タイトルと概要を入力
- **ステップ画面**: 4つのステップを表示・編集

## 🧪 将来の機能

- ユーザー認証とソーシャルログイン
- アイデアの共有機能
- ストリーク・報酬システム
- ランディングページ自動生成
- ストア投稿の自動化

## 📝 ライセンス

MIT License

## 👨‍💻 開発者

- あなたの名前 - [@yourusername](https://github.com/yourusername)
