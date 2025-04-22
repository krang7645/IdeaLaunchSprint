// widgets/build_step.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../models/todo.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class BuildStep extends StatefulWidget {
  final Idea idea;
  final ApiService apiService;
  final bool isReadOnly;
  final VoidCallback onTodoUpdated;

  const BuildStep({
    Key? key,
    required this.idea,
    required this.apiService,
    this.isReadOnly = false,
    required this.onTodoUpdated,
  }) : super(key: key);

  @override
  State<BuildStep> createState() => _BuildStepState();
}

class _BuildStepState extends State<BuildStep> {
  bool _isLoading = false;
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    if (widget.idea.todos != null) {
      _todos = widget.idea.todos!;
    }
  }

  Future<void> _generateTodos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final todos = await widget.apiService.generateTodos(widget.idea.id);
      setState(() {
        _todos = todos;
      });
      widget.onTodoUpdated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To-Do items generated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate To-Do items: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTodo(String todoId, bool done) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await widget.apiService.updateTodo(widget.idea.id, todoId, done);
      
      if (done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed! +24 hours added')),
        );
      }
      
      widget.onTodoUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update To-Do: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_todos.isEmpty) ...[
            const Text(
              '30分以内に完了できる小さなタスクに分割しましょう。',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            if (!widget.isReadOnly)
              ElevatedButton(
                onPressed: _isLoading ? null : _generateTodos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('AI に To-Do 生成を依頼'),
              ),
          ] else ...[
            const Text(
              'To-Do リスト（完了ごとに +24h）',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final todo in _todos) _buildTodoItem(todo),
            
            if (!widget.isReadOnly && _todos.length < 5) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateTodos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('More To-Do Items'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (widget.isReadOnly)
            Icon(
              todo.done ? Icons.check_box : Icons.check_box_outline_blank,
              color: todo.done ? AppConstants.progressColor : Colors.grey,
            )
          else
            Checkbox(
              value: todo.done,
              activeColor: AppConstants.progressColor,
              onChanged: (bool? value) {
                if (value != null) {
                  _updateTodo(todo.id, value);
                }
              },
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todo.text,
              style: TextStyle(
                decoration: todo.done ? TextDecoration.lineThrough : null,
                color: todo.done ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// widgets/publish_step.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PublishStep extends StatefulWidget {
  final Idea idea;
  final ApiService apiService;
  final bool isReadOnly;
  final VoidCallback onPublished;

  const PublishStep({
    Key? key,
    required this.idea,
    required this.apiService,
    this.isReadOnly = false,
    required this.onPublished,
  }) : super(key: key);

  @override
  State<PublishStep> createState() => _PublishStepState();
}

class _PublishStepState extends State<PublishStep> {
  final _platforms = [
    'App Store',
    'Google Play',
    'Web (GitHub Pages)',
    'Product Hunt',
    'Landing Page',
    'Social Media',
  ];
  
  String? _selectedPlatform;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = widget.idea.platform;
  }

  Future<void> _publishIdea() async {
    if (_selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a platform')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await widget.apiService.publishIdea(widget.idea.id, _selectedPlatform!);
      widget.onPublished();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Published to $_selectedPlatform!'),
          backgroundColor: AppConstants.progressColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublished = widget.idea.state == IdeaState.published;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPublished) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Published to ${widget.idea.platform}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Congratulations! Your idea is now live.'),
          ] else ...[
            const Text(
              'Choose a platform to publish your idea:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.isReadOnly && _selectedPlatform != null)
              Text('Selected: $_selectedPlatform')
            else
              Column(
                children: _platforms.map((platform) {
                  return RadioListTile<String>(
                    title: Text(platform),
                    value: platform,
                    groupValue: _selectedPlatform,
                    onChanged: widget.isReadOnly
                        ? null
                        : (String? value) {
                            setState(() {
                              _selectedPlatform = value;
                            });
                          },
                    activeColor: AppConstants.primaryColor,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            if (!widget.isReadOnly)
              ElevatedButton(
                onPressed: _isLoading ? null : _publishIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publish Now',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}