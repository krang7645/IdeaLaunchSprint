import 'package:flutter/material.dart';
import '../models/idea.dart';

class CaptureStep extends StatefulWidget {
  final Idea idea;
  final Function(Idea) onIdeaUpdated;

  const CaptureStep({
    Key? key,
    required this.idea,
    required this.onIdeaUpdated,
  }) : super(key: key);

  @override
  State<CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<CaptureStep> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea.title);
    _descriptionController = TextEditingController(text: widget.idea.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'アイデアの詳細',
            Icons.lightbulb_outline,
            const Color(0xFF3377FF),
            _isEditing ? _buildSaveButton() : _buildEditButton(),
          ),
          const SizedBox(height: 16),
          if (_isEditing) ...[
            _buildEditForm(),
          ] else ...[
            _buildIdeaDetails(),
          ],
          const SizedBox(height: 32),
          const _InfoBox(
            title: 'キャプチャーステップについて',
            icon: Icons.info_outline,
            content: 'このステップでは、あなたのアイデアの基本情報を記録します。タイトルと詳細な説明を入力して、アイデアを明確にしましょう。次のステップでは、アイデアの検証を行います。',
          ),
          const SizedBox(height: 16),
          const _InfoBox(
            title: '次のステップ：検証',
            icon: Icons.check_circle_outline,
            color: Color(0xFF6C56F9),
            content: '次のステップでは、アイデアの検証を行います。市場、問題、解決策について回答することで、アイデアを洗練させましょう。',
          ),
        ],
      ),
    );
  }

  // セクションヘッダー
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    Widget? action,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  // 編集ボタン
  Widget _buildEditButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _isEditing = true;
        });
      },
      icon: const Icon(Icons.edit, size: 16),
      label: const Text('編集'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
      ),
    );
  }

  // 保存ボタン
  Widget _buildSaveButton() {
    return TextButton.icon(
      onPressed: _saveChanges,
      icon: const Icon(Icons.save, size: 16),
      label: const Text('保存'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
      ),
    );
  }

  // アイデア詳細表示
  Widget _buildIdeaDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイトル',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.idea.title,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '説明',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.idea.description.isEmpty
              ? '説明はありません'
              : widget.idea.description,
          style: TextStyle(
            fontSize: 16,
            color: widget.idea.description.isEmpty
                ? Colors.grey
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // 編集フォーム
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイトル',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'アイデアのタイトルを入力',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '説明',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'アイデアの詳細を入力',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  // 変更を保存
  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedIdea = widget.idea.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    widget.onIdeaUpdated(updatedIdea);

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('変更を保存しました'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
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