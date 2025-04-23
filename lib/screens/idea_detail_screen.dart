import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../models/action.dart' as model;
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';

class IdeaDetailScreen extends StatefulWidget {
  final Idea idea;

  const IdeaDetailScreen({
    Key? key,
    required this.idea,
  }) : super(key: key);

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  late Idea _idea;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  model.ActionCategory? _selectedCategory;
  final _noteController = TextEditingController();
  bool _isAddingAction = false;

  @override
  void initState() {
    super.initState();
    _idea = widget.idea;
    print("[IdeaDetailScreen] initState: ApiService hashCode: ${_apiService.hashCode}");
    print("[IdeaDetailScreen] initState: Initial Idea ID: ${_idea.id}");
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_idea.title, overflow: TextOverflow.ellipsis),
        actions: [
           if (_idea.state == IdeaState.active)
             IconButton(
               icon: const Icon(Icons.archive_outlined),
               onPressed: () => _archiveIdeaDialog(context),
               tooltip: 'アーカイブ',
             ),
           IconButton(
             icon: const Icon(Icons.delete_outline),
             onPressed: () => _deleteIdeaDialog(context),
             tooltip: '削除',
           ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildIdeaHeader(),
                Expanded(
                  child: _buildActionHistoryList(),
                ),
                if (_idea.state == IdeaState.active)
                   _buildAddActionSection(),
              ],
            ),
    );
  }

  Widget _buildIdeaHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_idea.state),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(_idea.state),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (_idea.state == IdeaState.active) ...[
                _buildTimerChip('ゴール', _idea.remainingGoalDays, true),
                const SizedBox(width: 8),
                _buildTimerChip('アクション', _idea.remainingDays, false),
              ]
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ゴール: ${_idea.goal}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (_idea.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_idea.description, style: TextStyle(color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerChip(String label, int daysLeft, bool isGoalTimer) {
    Color chipColor = Colors.grey[200]!;
    Color textColor = Colors.grey[700]!;
    String suffix = 'd';

    if (daysLeft <= 0 && _idea.state == IdeaState.active) {
      chipColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      daysLeft = 0;
    } else if (daysLeft < (isGoalTimer ? 3 : 1) && _idea.state == IdeaState.active) {
       chipColor = Colors.orange[100]!;
       textColor = Colors.orange[800]!;
    }

    String timerText = '${daysLeft}${suffix}';
    if (_idea.state != IdeaState.active) {
       timerText = '-';
       chipColor = Colors.grey[300]!;
       textColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $timerText',
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionHistoryList() {
    final actions = _idea.actions ?? <model.Action>[];

    if (actions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _idea.state == IdeaState.active
             ? 'まだアクションがありません。\n最初のアクションを追加しましょう！'
             : 'アクション履歴はありません。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    final sortedActions = List<model.Action>.from(actions)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: sortedActions.length,
      itemBuilder: (context, index) {
        final action = sortedActions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(action.category.icon, color: Theme.of(context).primaryColor, size: 28),
            title: Text(action.category.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if(action.note.isNotEmpty) Padding(
                   padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                   child: Text(action.note),
                 ),
                 Text(
                   DateFormatter.formatDateTime(action.createdAt),
                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                 ),
              ],
            ),
            isThreeLine: action.note.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _buildAddActionSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<model.ActionCategory>(
              value: _selectedCategory,
              hint: const Text('アクションカテゴリを選択'),
              items: model.ActionCategory.values
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                           children: [
                             Icon(category.icon, size: 18),
                             const SizedBox(width: 8),
                             Text(category.displayName),
                           ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'カテゴリを選択してください' : null,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'アクションのメモ',
                hintText: '具体的な内容を記入してください',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAddingAction ? null : _addAction,
              icon: _isAddingAction
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: const Text('アクションを追加'),
              style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAction() async {
    print("[IdeaDetailScreen] _addAction started.");
    print("[IdeaDetailScreen] _addAction: Current Idea ID: ${_idea.id}");
    if (!(_formKey.currentState?.validate() ?? false)) {
      print("[IdeaDetailScreen] Form validation failed.");
      return;
    }
    if (_selectedCategory == null) {
       print("[IdeaDetailScreen] Category not selected.");
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('アクションカテゴリを選択してください')),
       );
       return;
    }

    setState(() {
      _isAddingAction = true;
    });

    print("[IdeaDetailScreen] Checking current idea status before adding action. ID: ${_idea.id}");

    try {
      final currentIdeaState = await _apiService.getIdeaById(_idea.id);
      if (currentIdeaState == null || currentIdeaState.state != IdeaState.active) {
        print("[IdeaDetailScreen] Error: Idea is no longer active or not found before adding action. Current state: ${currentIdeaState?.state}");
        _showError('アイデアがアクティブでないため、アクションを追加できません。リストを更新してください。');
        setState(() { _isAddingAction = false; });
        return;
      }
      print("[IdeaDetailScreen] Idea is active. Proceeding to add action.");

      print("[IdeaDetailScreen] Calling ApiService.addAction with category: ${_selectedCategory!.name}, note: ${_noteController.text.trim()}");

      final updatedIdea = await _apiService.addAction(
        _idea.id,
        _selectedCategory!,
        _noteController.text.trim(),
      );
      print("[IdeaDetailScreen] ApiService.addAction successful. Updated Idea ID: ${updatedIdea.id}");

      if (mounted) {
        setState(() {
          print("[IdeaDetailScreen] Updating state with new idea.");
          _idea = updatedIdea;
          _selectedCategory = null;
          _noteController.clear();
          _formKey.currentState?.reset();
        });
        print("[IdeaDetailScreen] State updated.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedIdea.actions?.last.category.displayName ?? 'アクション'}を追加しました')),
        );

        if (updatedIdea.state == IdeaState.published) {
           print("[IdeaDetailScreen] Idea published. Popping screen.");
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('🎉 ゴール達成！おめでとうございます！'),
                  backgroundColor: Colors.green),
           );
           Navigator.pop(context);
         }
       } else {
          print("[IdeaDetailScreen] Widget not mounted after ApiService call.");
       }

    } catch (e) {
      print("[IdeaDetailScreen] Error adding action: $e");
       if(mounted) {
          _showError('アクションの追加に失敗しました: ${e.toString()}');
       }
    } finally {
       if(mounted) {
          setState(() {
            _isAddingAction = false;
          });
          print("[IdeaDetailScreen] _isAddingAction set to false.");
       }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.dangerColor,
      ),
    );
  }

  String _getStatusText(IdeaState state) {
    switch (state) {
      case IdeaState.active: return 'アクティブ';
      case IdeaState.archived: return 'アーカイブ';
      case IdeaState.published: return '達成済み';
    }
  }

  Color _getStatusColor(IdeaState state) {
     switch (state) {
      case IdeaState.active: return Colors.blue;
      case IdeaState.archived: return Colors.grey;
      case IdeaState.published: return Colors.green;
    }
  }

  Future<void> _archiveIdeaDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイデアをアーカイブ'),
        content: Text('${_idea.title} をアーカイブしてもよろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('アーカイブする', style: TextStyle(color: Colors.orange)),
           ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.archiveIdea(_idea.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_idea.title} をアーカイブしました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アーカイブに失敗: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteIdeaDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイデアを削除'),
        content: Text('${_idea.title} を完全に削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteIdea(_idea.id);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_idea.title} を削除しました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗: ${e.toString()}')),
        );
      }
    }
  }
}