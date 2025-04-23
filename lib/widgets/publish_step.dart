import 'package:flutter/material.dart';
import '../models/idea.dart';

class PublishStep extends StatefulWidget {
  final Idea idea;
  final Function(Idea) onIdeaUpdated;

  const PublishStep({
    Key? key,
    required this.idea,
    required this.onIdeaUpdated,
  }) : super(key: key);

  @override
  State<PublishStep> createState() => _PublishStepState();
}

class _PublishStepState extends State<PublishStep> {
  String _selectedPlatform = 'website';
  bool _isPublishing = false;

  final _platforms = [
    {'id': 'website', 'name': 'ウェブサイト', 'icon': Icons.language},
    {'id': 'social_media', 'name': 'ソーシャルメディア', 'icon': Icons.people},
    {'id': 'app_store', 'name': 'アプリストア', 'icon': Icons.apps},
    {'id': 'crowdfunding', 'name': 'クラウドファンディング', 'icon': Icons.monetization_on},
    {'id': 'blog', 'name': 'ブログ', 'icon': Icons.article},
  ];

  @override
  void initState() {
    super.initState();
    // アイデアに既に公開プラットフォームが設定されている場合はそれを使用
    if (widget.idea.publishPlatform != null) {
      _selectedPlatform = widget.idea.publishPlatform!;
    }
  }

  Future<void> _publishIdea() async {
    setState(() {
      _isPublishing = true;
    });

    try {
      final updatedIdea = widget.idea.publish();
      await widget.onIdeaUpdated(updatedIdea);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイデアが公開されました！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('公開に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyPublished = widget.idea.state == IdeaState.published;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'アイデアを公開する',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isAlreadyPublished)
                Chip(
                  label: const Text('公開済み'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 説明ボックス
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '公開ステップについて',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'このステップでは、あなたのアイデアを世界に公開します。適切なプラットフォームを選んで、アイデアの可能性を最大限に引き出しましょう。',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 公開チェックリスト
          const Text(
            '公開前チェックリスト',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildChecklistItem(
            '検証ステップを完了しましたか？',
            widget.idea.step.index >= IdeaStep.build.index,
          ),
          _buildChecklistItem(
            '構築ステップのタスクを完了しましたか？',
            widget.idea.todos != null &&
            widget.idea.todos!.isNotEmpty &&
            widget.idea.todos!.every((todo) => todo.done),
          ),
          _buildChecklistItem(
            'アイデアを他者にレビューしてもらいましたか？',
            true, // デモのためtrueにしています
          ),
          const SizedBox(height: 24),

          // プラットフォーム選択
          const Text(
            '公開プラットフォームを選択',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ..._platforms.map((platform) => _buildPlatformOption(
            platform['id'] as String,
            platform['name'] as String,
            platform['icon'] as IconData,
          )),
          const SizedBox(height: 32),

          // 公開ボタン
          Center(
            child: ElevatedButton.icon(
              onPressed: isAlreadyPublished || _isPublishing ? null : _publishIdea,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rocket_launch),
              label: Text(isAlreadyPublished ? '公開済み' : '公開する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (isAlreadyPublished) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'おめでとうございます！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'アイデアが${_getPlatformName(widget.idea.publishPlatform)}で公開されました。',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '次のステップ：フィードバックを集めて改善しましょう！',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPlatformName(String? platformId) {
    if (platformId == null) return '';
    final platform = _platforms.firstWhere(
      (p) => p['id'] == platformId,
      orElse: () => {'name': '不明なプラットフォーム'});
    return platform['name'] as String;
  }

  Widget _buildChecklistItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.check_circle_outline,
            color: isChecked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isChecked ? Colors.black : Colors.grey[600],
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformOption(String id, String name, IconData icon) {
    final isSelected = _selectedPlatform == id;
    final isPublished = widget.idea.state == IdeaState.published;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.green
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: id,
        groupValue: _selectedPlatform,
        onChanged: isPublished ? null : (value) {
          setState(() {
            _selectedPlatform = value!;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}