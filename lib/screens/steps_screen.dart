import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../widgets/build_step.dart';
import '../widgets/publish_step.dart';
import '../utils/constants.dart';
import '../widgets/idea_card.dart';

class StepsScreen extends StatefulWidget {
  final Idea idea;

  const StepsScreen({
    Key? key,
    required this.idea,
  }) : super(key: key);

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  late Idea _idea;

  @override
  void initState() {
    super.initState();
    _idea = widget.idea;
  }

  void _updateIdea(Idea updatedIdea) {
    setState(() {
      _idea = updatedIdea;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アイデア: ${_idea.title}'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 上部のプログレスバー
          _buildProgressBar(),

          // メインコンテンツ
          Expanded(
            child: _buildCurrentStep(),
          ),

          // 下部のアクションボタン
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '進捗状況',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_idea.expireAt != null)
                Text(
                  '有効期限: あと${_idea.remainingDays}日',
                  style: TextStyle(
                    color: _idea.remainingDays < 2 ? AppConstants.dangerColor : Colors.grey[700],
                    fontWeight: _idea.remainingDays < 2 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _idea.getStepProgress(),
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStepColor(_idea.step),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(IdeaStep.capture, 'キャプチャー'),
              _buildStepIndicator(IdeaStep.validate, '検証'),
              _buildStepIndicator(IdeaStep.build, '構築'),
              _buildStepIndicator(IdeaStep.publish, '公開'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(IdeaStep step, String label) {
    final isCurrentStep = _idea.step == step;
    final isCompletedStep = _idea.step.index > step.index;
    final isActive = isCurrentStep || isCompletedStep;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _getStepColor(step) : Colors.grey[300],
            border: Border.all(
              color: isCurrentStep ? _getStepColor(step) : Colors.transparent,
              width: 2,
            ),
          ),
          child: isCompletedStep
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? _getStepColor(step) : Colors.grey,
            fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_idea.step) {
      case IdeaStep.capture:
        return CaptureStep(idea: _idea, isReadOnly: _idea.step.index > IdeaStep.capture.index);
      case IdeaStep.validate:
        return _buildValidateStep();
      case IdeaStep.build:
        return BuildStep(
          idea: _idea,
          onIdeaUpdated: _updateIdea,
        );
      case IdeaStep.publish:
        return PublishStep(
          idea: _idea,
          onIdeaUpdated: _updateIdea,
        );
      default:
        return const Center(child: Text('不明なステップです'));
    }
  }

  Widget _buildCaptureStep() {
    // キャプチャーステップのUIを実装
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            _idea.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _idea.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'アイデアをキャプチャーしました！次のステップで検証しましょう。',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateStep() {
    // 検証ステップのUIを実装
    final validateAnswers = _idea.validateAnswers ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アイデアの検証',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'このステップでは、アイデアが解決する問題と提供する解決策を明確にします。以下の質問に答えてアイデアを検証しましょう。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // 解決する問題
          _buildValidateField(
            label: 'どのような問題を解決しますか？',
            value: validateAnswers['problem'] ?? '未回答',
            icon: Icons.help_outline,
            color: AppConstants.dangerColor,
          ),

          // 解決策
          _buildValidateField(
            label: 'どのように解決しますか？',
            value: validateAnswers['solution'] ?? '未回答',
            icon: Icons.lightbulb_outline,
            color: AppConstants.accentColor,
          ),

          // ターゲット市場
          _buildValidateField(
            label: 'ターゲットとなる市場は？',
            value: validateAnswers['market'] ?? '未回答',
            icon: Icons.people_outline,
            color: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildValidateField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontStyle: value == '未回答' ? FontStyle.italic : null,
              color: value == '未回答' ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 前のステップに戻るボタン
          if (_idea.step.index > 0)
            OutlinedButton.icon(
              onPressed: _moveTopPreviousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('前へ'),
            )
          else
            const SizedBox(width: 100),

          // 延長ボタン
          if (_idea.expireAt != null)
            ElevatedButton.icon(
              onPressed: _extendActionDeadline,
              icon: const Icon(Icons.timer),
              label: const Text('有効期限を延長'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.warningColor,
                foregroundColor: Colors.white,
              ),
            ),

          // 次のステップに進むボタン
          if (_idea.step.index < IdeaStep.values.length - 1)
            ElevatedButton.icon(
              onPressed: _moveToNextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('次へ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStepColor(_idea.step),
                foregroundColor: Colors.white,
              ),
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  void _moveToNextStep() {
    if (_idea.step.index < IdeaStep.values.length - 1) {
      final nextStep = IdeaStep.values[_idea.step.index + 1];
      final updatedIdea = _idea.copyWith(step: nextStep);
      _updateIdea(updatedIdea);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('既に最終ステップです。')),
      );
    }
  }

  void _moveTopPreviousStep() {
    // 現在のステップから1つ前のステップに移動
    if (_idea.step.index > 0) {
      final previousStep = IdeaStep.values[_idea.step.index - 1];
      final updatedIdea = _idea.copyWith(step: previousStep);
      _updateIdea(updatedIdea);
    }
  }

  void _extendActionDeadline() {
    // 有効期限を24時間延長
    final extendedIdea = _idea.extendActionDeadline(const Duration(hours: 24));
    _updateIdea(extendedIdea);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('有効期限を24時間延長しました')),
    );
  }

  Color _getStepColor(IdeaStep step) {
    switch (step) {
      case IdeaStep.capture:
        return AppConstants.primaryColor;
      case IdeaStep.validate:
        return AppConstants.progressColor;
      case IdeaStep.build:
        return AppConstants.secondaryColor;
      case IdeaStep.publish:
        return AppConstants.accentColor;
      default:
        return Colors.grey;
    }
  }
}