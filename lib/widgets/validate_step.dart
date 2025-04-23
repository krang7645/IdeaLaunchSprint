import 'package:flutter/material.dart';
import '../models/idea.dart';

class ValidateStep extends StatefulWidget {
  final Idea idea;
  final Function(Idea) onIdeaUpdated;

  const ValidateStep({
    Key? key,
    required this.idea,
    required this.onIdeaUpdated,
  }) : super(key: key);

  @override
  State<ValidateStep> createState() => _ValidateStepState();
}

class _ValidateStepState extends State<ValidateStep> {
  final List<Map<String, dynamic>> _validationQuestions = [
    {
      'id': 'problem',
      'question': 'このアイデアが解決する問題は何ですか？',
      'hint': '例：多くの人が冷蔵庫の食材を有効活用できずに無駄にしている',
      'icon': Icons.help_outline,
    },
    {
      'id': 'solution',
      'question': 'その問題をどのように解決しますか？',
      'hint': '例：AIを使って冷蔵庫の食材から最適なレシピを提案する',
      'icon': Icons.lightbulb_outline,
    },
    {
      'id': 'market',
      'question': 'ターゲット市場と潜在的なユーザーは誰ですか？',
      'hint': '例：料理が苦手な若い社会人や、忙しい家族',
      'icon': Icons.people_outline,
    },
  ];

  late Map<String, TextEditingController> _answerControllers;

  @override
  void initState() {
    super.initState();

    // テキストコントローラーを初期化
    _answerControllers = {};

    for (final question in _validationQuestions) {
      final questionId = question['id'] as String;
      final existingAnswer = widget.idea.validateAnswers?[questionId] ?? '';
      _answerControllers[questionId] = TextEditingController(text: existingAnswer);
    }
  }

  @override
  void dispose() {
    // テキストコントローラーを破棄
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = widget.idea.validateAnswers?.length ?? 0;
    final totalQuestions = _validationQuestions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: const Color(0xFF6C56F9)),
              const SizedBox(width: 8),
              const Text(
                'アイデアの検証',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 進捗状況
          Row(
            children: [
              Text(
                '$answeredCount/$totalQuestions 回答済み',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              if (answeredCount > 0) ...[
                const Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${answeredCount * 48}時間',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // 検証の説明
          const _InfoBox(
            title: '検証ステップについて',
            icon: Icons.info_outline,
            content: 'アイデアを検証するために、以下の3つの質問に答えてください。各質問に答えると有効期限が48時間延長されます。',
          ),
          const SizedBox(height: 24),
          // 質問リスト
          ...List.generate(_validationQuestions.length, (index) {
            final question = _validationQuestions[index];
            final questionId = question['id'] as String;
            final isAnswered = widget.idea.validateAnswers?.containsKey(questionId) ?? false;

            return Column(
              children: [
                _ValidationQuestionItem(
                  question: question['question'] as String,
                  hint: question['hint'] as String,
                  icon: question['icon'] as IconData,
                  controller: _answerControllers[questionId]!,
                  isAnswered: isAnswered,
                  onSave: () => _saveAnswer(questionId),
                ),
                if (index < _validationQuestions.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 24),
          // AIアシスタントボタン
          _buildAIAssistantButton(),
        ],
      ),
    );
  }

  // 回答を保存
  void _saveAnswer(String questionId) {
    final answer = _answerControllers[questionId]!.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('回答を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 現在の回答を取得または新規作成
    final currentAnswers = Map<String, String>.from(
      widget.idea.validateAnswers ?? {},
    );

    // 新しい回答があるかどうかチェック
    final isNewAnswer = !currentAnswers.containsKey(questionId);

    // 回答を更新
    currentAnswers[questionId] = answer;

    // アイデアを更新
    Idea updatedIdea = widget.idea.copyWith(
      validateAnswers: currentAnswers,
    );

    // 新しい回答の場合は期限を延長（48時間）
    if (isNewAnswer) {
      updatedIdea = updatedIdea.extendDeadline(const Duration(hours: 48));
    }

    widget.onIdeaUpdated(updatedIdea);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNewAnswer ? '回答を保存しました（+48時間）' : '回答を更新しました'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // AIアシスタントボタン
  Widget _buildAIAssistantButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF6C56F9),
              ),
              SizedBox(width: 8),
              Text(
                'AIアシスタント',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C56F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'アイデアの検証に困ったら、AIアシスタントに質問することができます。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showAIAssistant,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('AIアシスタントに質問する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C56F9),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  // AIアシスタントダイアログを表示
  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.smart_toy_outlined,
              color: Color(0xFF6C56F9),
            ),
            SizedBox(width: 8),
            Text('AIアシスタント'),
          ],
        ),
        content: const Text(
          '※実際のアプリでは、ここでAIアシスタントが質問に答えたり、アイデアの検証をサポートします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// 質問アイテム
class _ValidationQuestionItem extends StatefulWidget {
  final String question;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isAnswered;
  final VoidCallback onSave;

  const _ValidationQuestionItem({
    Key? key,
    required this.question,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isAnswered,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_ValidationQuestionItem> createState() => _ValidationQuestionItemState();
}

class _ValidationQuestionItemState extends State<_ValidationQuestionItem> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isAnswered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isAnswered
            ? const Color(0xFF6C56F9).withOpacity(0.05)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isAnswered
              ? const Color(0xFF6C56F9).withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isAnswered
                        ? const Color(0xFF6C56F9)
                        : Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.isAnswered
                          ? const Color(0xFF6C56F9)
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
              if (widget.isAnswered && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.grey[600],
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing) ...[
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isAnswered)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // 元の値に戻す
                        widget.controller.text = widget.controller.text;
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C56F9),
                  ),
                  child: Text(widget.isAnswered ? '更新' : '保存'),
                ),
              ],
            ),
          ] else ...[
            Text(
              widget.controller.text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;

  const _InfoBox({
    Key? key,
    required this.title,
    required this.icon,
    this.color = Colors.blue,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}