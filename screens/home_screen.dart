// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import '../widgets/idea_card.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Idea> _ideas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ideas = await _apiService.getActiveIdeas();
      setState(() {
        _ideas = ideas;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ideas: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaunchPad Notebook'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ideas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No active ideas yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_idea')
                              .then((_) => _loadIdeas());
                        },
                        child: const Text('Add Your First Idea'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIdeas,
                  child: ListView.builder(
                    itemCount: _ideas.length,
                    itemBuilder: (context, index) {
                      final idea = _ideas[index];
                      return Dismissible(
                        key: Key(idea.id),
                        background: Container(
                          color: AppConstants.progressColor,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(
                            Icons.add_alarm,
                            color: Colors.white,
                          ),
                        ),
                        secondaryBackground: Container(
                          color: AppConstants.dangerColor,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Extend deadline by 24 hours
                            await _apiService.extendDeadline(idea.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Deadline extended by 24 hours'),
                              ),
                            );
                            _loadIdeas();
                            return false;
                          } else {
                            // Archive idea
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Archive Idea'),
                                  content: Text(
                                      'Are you sure you want to archive "${idea.title}"?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Archive'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await _apiService.archiveIdea(idea.id);
                            setState(() {
                              _ideas.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${idea.title} archived'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    // Implement undo functionality if needed
                                    _loadIdeas();
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: IdeaCard(
                          idea: idea,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/steps',
                              arguments: idea,
                            ).then((_) => _loadIdeas());
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_idea').then((_) => _loadIdeas());
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// screens/add_idea_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AddIdeaScreen extends StatefulWidget {
  const AddIdeaScreen({Key? key}) : super(key: key);

  @override
  State<AddIdeaScreen> createState() => _AddIdeaScreenState();
}

class _AddIdeaScreenState extends State<AddIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _saveIdea() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.createIdea(
          _titleController.text,
          _summaryController.text,
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save idea: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Idea'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary (≤140 characters)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 140,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '残り 7 日',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('保存して開始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// screens/steps_screen.dart
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/capture_step.dart';
import '../widgets/validate_step.dart';
import '../widgets/build_step.dart';
import '../widgets/publish_step.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({Key? key}) : super(key: key);

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  late Idea _idea;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    _idea = ModalRoute.of(context)!.settings.arguments as Idea;

    return Scaffold(
      appBar: AppBar(
        title: Text(_idea.title),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildCaptureStep(),
                      _buildValidateStep(),
                      _buildBuildStep(),
                      _buildPublishStep(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    int stepIndex = _idea.step.index;
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: index <= stepIndex
                    ? AppConstants.progressColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, bool isExpanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isExpanded ? AppConstants.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpanded ? AppConstants.primaryColor : Colors.black,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isExpanded ? AppConstants.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureStep() {
    bool isCurrentStep = _idea.step == IdeaStep.capture;
    bool isCompleted = _idea.step.index > IdeaStep.capture.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Capture ${isCompleted ? '✓' : ''}',
          isCurrentStep,
          () {
            // Toggle expansion if needed
          },
        ),
        if (isCurrentStep || isCompleted)
          CaptureStep(
            idea: _idea,
            isReadOnly: isCompleted,
          ),
      ],
    );
  }

  Widget _buildValidateStep() {
    bool isCurrentStep = _idea.step == IdeaStep.validate;
    bool isCompleted = _idea.step.index > IdeaStep.validate.index;
    bool isEnabled = _idea.step.index >= IdeaStep.validate.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Validate ${isCompleted ? '✓' : ''}',
          isCurrentStep,
          () {
            // Toggle expansion if needed
          },
        ),
        if (isCurrentStep || isCompleted)
          ValidateStep(
            idea: _idea,
            apiService: _apiService,
            isReadOnly: isCompleted,
            onAnswerSaved: () {
              setState(() {
                _isLoading = true;
              });
              
              // Refresh idea data
              _apiService.getActiveIdeas().then((ideas) {
                final updatedIdea = ideas.firstWhere((i) => i.id == _idea.id);
                setState(() {
                  _idea = updatedIdea;
                  _isLoading = false;
                });
              });
            },
          ),
      ],
    );
  }

  Widget _buildBuildStep() {
    bool isCurrentStep = _idea.step == IdeaStep.build;
    bool isCompleted = _idea.step.index > IdeaStep.build.index;
    bool isEnabled = _idea.step.index >= IdeaStep.build.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Build ${isCompleted ? '✓' : ''}',
          isCurrentStep,
          () {
            // Toggle expansion if needed
          },
        ),
        if (isCurrentStep || isCompleted)
          BuildStep(
            idea: _idea,
            apiService: _apiService,
            isReadOnly: isCompleted,
            onTodoUpdated: () {
              setState(() {
                _isLoading = true;
              });
              
              // Refresh idea data
              _apiService.getActiveIdeas().then((ideas) {
                final updatedIdea = ideas.firstWhere((i) => i.id == _idea.id);
                setState(() {
                  _idea = updatedIdea;
                  _isLoading = false;
                });
              });
            },
          ),
      ],
    );
  }

  Widget _buildPublishStep() {
    bool isCurrentStep = _idea.step == IdeaStep.publish;
    bool isCompleted = _idea.state == IdeaState.published;
    bool isEnabled = _idea.step.index >= IdeaStep.publish.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Publish ${isCompleted ? '✓' : ''}',
          isCurrentStep,
          () {
            // Toggle expansion if needed
          },
        ),
        if (isCurrentStep || isCompleted)
          PublishStep(
            idea: _idea,
            apiService: _apiService,
            isReadOnly: isCompleted,
            onPublished: () {
              setState(() {
                _isLoading = true;
              });
              
              // Refresh idea data
              _apiService.getActiveIdeas().then((ideas) {
                final updatedIdea = ideas.firstWhere((i) => i.id == _idea.id);
                setState(() {
                  _idea = updatedIdea;
                  _isLoading = false;
                });
              }).catchError((e) {
                // Handle published ideas that may no longer appear in active list
                Navigator.pop(context);
              });
            },
          ),
      ],
    );
  }