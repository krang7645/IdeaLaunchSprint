// widgets/idea_card.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../utils/constants.dart';

class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback onTap;

  const IdeaCard({
    Key? key,
    required this.idea,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: idea.timerColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatRemainingTime(idea.remainingTime),
                          style: TextStyle(
                            color: idea.timerColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: idea.timerColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) {
      return '期限切れ';
    }
    
    if (duration.inDays > 0) {
      return '残り ${duration.inDays} 日';
    } else if (duration.inHours > 0) {
      return '残り ${duration.inHours} 時間';
    } else {
      return '残り ${duration.inMinutes} 分';
    }
  }
}

// widgets/capture_step.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';

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
            idea.summary,
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
    return '${date.year}/${date.month}/${date.day}';
  }
}

// widgets/validate_step.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ValidateStep extends StatefulWidget {
  final Idea idea;
  final ApiService apiService;
  final bool isReadOnly;
  final VoidCallback onAnswerSaved;

  const ValidateStep({
    Key? key,
    required this.idea,
    required this.apiService,
    this.isReadOnly = false,
    required this.onAnswerSaved,
  }) : super(key: key);

  @override
  State<ValidateStep> createState() => _ValidateStepState();
}

class _ValidateStepState extends State<ValidateStep> {
  final _formKey = GlobalKey<FormState>();
  
  final _questions = [
    'ターゲットユーザー（誰のために）',
    '解決する問題（どんな課題を）',
    '既存の代替品（現在どう解決されている）',
  ];
  
  final Map<String, String> _answers = {
    'q1': '',
    'q2': '',
    'q3': '',
  };
  
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize answers from idea if available
    if (widget.idea.answers != null) {
      _answers['q1'] = widget.idea.answers!['q1'] ?? '';
      _answers['q2'] = widget.idea.answers!['q2'] ?? '';
      _answers['q3'] = widget.idea.answers!['q3'] ?? '';
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });
    
    try {
      final suggestions = await widget.apiService.generateValidationAnswers();
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load suggestions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAnswers() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await widget.apiService.saveAnswers(widget.idea.id, _answers);
        widget.onAnswerSaved();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answers saved. +48 hours added!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save answers: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _useSuggestion(int questionIndex, String suggestion) {
    setState(() {
      _answers['q${questionIndex + 1}'] = suggestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _questions.length; i++) _buildQuestionField(i),
            
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAnswers,
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
                        : const Text('Save Answers'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _isLoading || _showSuggestions
                        ? null
                        : _loadSuggestions,
                    child: const Text('Get Suggestions'),
                  ),
                ],
              ),
            ],
            
            if (_showSuggestions && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < _suggestions.length; i++)
                _buildSuggestionChip(i, _suggestions[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionField(int index) {
    final questionKey = 'q${index + 1}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _questions[index],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isReadOnly)
            Text(_answers[questionKey] ?? '')
          else
            TextFormField(
              initialValue: _answers[questionKey],
              decoration: InputDecoration(
                hintText: 'Enter ${_questions[index].toLowerCase()}',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _answers[questionKey] = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an answer';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(int index, String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('Q${index + 1}:'),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(suggestion),
            onPressed: widget.isReadOnly
                ? null
                : () => _useSuggestion(index, suggestion),
          ),
        ],
      ),
    );
  }
}