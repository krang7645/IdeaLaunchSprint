// widgets/build_step.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../models/todo.dart';
import '../services/api_service.dart';
import '../services/todo_service.dart';
import '../utils/date_formatter.dart';

class BuildStep extends StatefulWidget {
  final Idea idea;
  final Function(Idea) onIdeaUpdated;

  const BuildStep({
    Key? key,
    required this.idea,
    required this.onIdeaUpdated,
  }) : super(key: key);

  @override
  State<BuildStep> createState() => _BuildStepState();
}

class _BuildStepState extends State<BuildStep> {
  final ApiService _apiService = ApiService();
  final TodoService _todoService = TodoService();
  bool _isLoading = false;
  List<Todo> _todos = [];
  final _newTodoController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _newTodoController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // すでにTodoがあればそれを使用
      if (widget.idea.todos != null && widget.idea.todos!.isNotEmpty) {
        _todos = widget.idea.todos!;
      } else {
        // なければAPIから生成
        _todos = await _apiService.generateTodos(widget.idea.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todoの読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTodo() async {
    if (_newTodoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タスクを入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newTodo = await _todoService.createTodo(
        ideaId: widget.idea.id,
        title: _newTodoController.text,
        dueDate: _selectedDueDate,
      );

      if (newTodo != null) {
        final updatedTodos = [..._todos, newTodo];
        setState(() {
          _todos = updatedTodos;
          _newTodoController.clear();
          _selectedDueDate = null;
        });

        // アイデアを更新
        final updatedIdea = widget.idea.copyWith(todos: updatedTodos);
        widget.onIdeaUpdated(updatedIdea);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タスクの追加に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTodoStatus(Todo todo) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTodo = await _todoService.toggleTodoStatus(todo.id);
      if (updatedTodo != null) {
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          final updatedTodos = List<Todo>.from(_todos);
          updatedTodos[index] = updatedTodo;

          setState(() {
            _todos = updatedTodos;
          });

          // アイデアを更新
          final updatedIdea = widget.idea.copyWith(todos: updatedTodos);
          widget.onIdeaUpdated(updatedIdea);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タスクの更新に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「${todo.title}」を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _todoService.deleteTodo(todo.id);
      if (success) {
        final updatedTodos = _todos.where((t) => t.id != todo.id).toList();
        setState(() {
          _todos = updatedTodos;
        });

        // アイデアを更新
        final updatedIdea = widget.idea.copyWith(todos: updatedTodos);
        widget.onIdeaUpdated(updatedIdea);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タスクの削除に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: '期限日を選択',
      cancelText: 'キャンセル',
      confirmText: '設定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'アイデアを実装する',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_todos.isNotEmpty)
                Text(
                  '完了: ${_todos.where((t) => t.done).length}/${_todos.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 説明ボックス
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      '構築ステップについて',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'このステップでは、アイデアを実現するための具体的なタスクを設定し、実行していきます。タスクリストを作成し、一つずつ完了させていきましょう。',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // タスク入力フォーム
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '新しいタスクを追加',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTodoController,
                          decoration: const InputDecoration(
                            hintText: 'タスクを入力',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            onPressed: _selectDueDate,
                            icon: const Icon(Icons.calendar_today),
                            tooltip: '期限を設定',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            onPressed: _isLoading ? null : _addTodo,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            tooltip: '追加',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_selectedDueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Chip(
                        label: Text(
                          '期限: ${DateFormatter.formatDateJapanese(_selectedDueDate!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // タスクリスト
          const Text(
            'タスクリスト',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading && _todos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_todos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.assignment, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'タスクがありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '上のフォームからタスクを追加しましょう',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildTodoList(),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    // 完了していないタスクを上部に、完了したタスクを下部に表示
    final uncompletedTodos = _todos.where((todo) => !todo.done).toList();
    final completedTodos = _todos.where((todo) => todo.done).toList();

    return Column(
      children: [
        ...uncompletedTodos.map((todo) => _buildTodoItem(todo)),
        if (completedTodos.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '完了したタスク (${completedTodos.length})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...completedTodos.map((todo) => _buildTodoItem(todo)),
        ],
      ],
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: todo.done
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: CheckboxListTile(
          value: todo.done,
          onChanged: (value) => _toggleTodoStatus(todo),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.done ? TextDecoration.lineThrough : null,
              color: todo.done ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.dueDate != null || todo.completedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (todo.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: _isOverdue(todo)
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '期限: ${DateFormatter.formatDate(todo.dueDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOverdue(todo)
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (todo.dueDate != null && todo.completedAt != null)
                      const SizedBox(width: 16),
                    if (todo.completedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '完了: ${DateFormatter.formatDate(todo.completedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
          secondary: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteTodo(todo),
            tooltip: '削除',
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          controlAffinity: ListTileControlAffinity.leading,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          activeColor: Colors.orange,
        ),
      ),
    );
  }

  bool _isOverdue(Todo todo) {
    if (todo.done || todo.dueDate == null) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }
}