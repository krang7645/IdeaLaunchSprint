// widgets/idea_card.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';
import '../models/action.dart' as model; // model.ActionCategory を使う可能性は低いが念のため

class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const IdeaCard({
    Key? key,
    required this.idea,
    required this.onTap,
    this.onArchive,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.flag_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          idea.goal,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (idea.state == IdeaState.active && idea.remainingGoalDays > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GOAL ⏳ ${idea.remainingGoalDays}d',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                      _buildActions(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    idea.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (idea.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      idea.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    Color iconColor = Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onArchive != null && idea.state == IdeaState.active)
          IconButton(
            icon: Icon(Icons.archive_outlined, color: iconColor, size: 20),
            onPressed: onArchive,
            tooltip: 'アーカイブ',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (onArchive != null && idea.state == IdeaState.active)
          const SizedBox(width: 8),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, color: iconColor, size: 20),
            onPressed: onDelete,
            tooltip: '削除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    String timeInfo = '作成日: ${DateFormatter.formatDate(idea.createdAt)}';
    Color timeColor = Colors.grey[600]!;
    FontWeight timeWeight = FontWeight.w500;

    if (idea.state == IdeaState.active) {
      final daysLeft = idea.remainingDays;
      final hoursLeft = idea.remainingHours;

      if (daysLeft > 0) {
        timeInfo = 'アクション期限: 残り $daysLeft 日';
      } else if (hoursLeft > 0) {
        timeInfo = 'アクション期限: 残り $hoursLeft 時間';
      } else {
        timeInfo = 'アクション期限: 期限切れ';
        timeColor = Colors.red;
        timeWeight = FontWeight.bold;
      }
    } else if (idea.state == IdeaState.published) {
       timeInfo = 'ゴール達成日: ${DateFormatter.formatDate(idea.updatedAt ?? idea.createdAt)}';
    } else if (idea.state == IdeaState.archived) {
       timeInfo = 'アーカイブ日: ${DateFormatter.formatDate(idea.updatedAt ?? idea.createdAt)}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          timeInfo,
          style: TextStyle(
            fontSize: 12,
            color: timeColor,
            fontWeight: timeWeight,
          ),
        ),
      ],
    );
  }
}

// widgets/capture_step.dart
class CaptureStep extends StatelessWidget {
  final Idea idea;
  final bool isReadOnly;

  const CaptureStep({
    Key? key,
    required this.idea,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('タイトル:'),
          const SizedBox(height: 4),
          Text(
            idea.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text('概要:'),
          const SizedBox(height: 4),
          Text(
            idea.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(
                '作成日: ${_formatDate(idea.createdAt)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }
}