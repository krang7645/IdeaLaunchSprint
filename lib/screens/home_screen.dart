// screens/home_screen.dart
import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase 不要に
import '../models/idea.dart';
import '../services/api_service.dart';
import '../widgets/idea_card.dart';
import '../utils/constants.dart';
import 'idea_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  // final supabase = Supabase.instance.client; // Supabase クライアント 不要に

  List<Idea> _activeIdeas = [];
  List<Idea> _archivedIdeas = [];
  List<Idea> _publishedIdeas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("[HomeScreen] initState: ApiService hashCode: ${_apiService.hashCode}"); // DEBUG PRINT
    _tabController = TabController(length: 3, vsync: this);
    _loadIdeas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeIdeas = await _apiService.getActiveIdeas();
      final archivedIdeas = await _apiService.getArchivedIdeas();
      final publishedIdeas = await _apiService.getPublishedIdeas();

      setState(() {
        _activeIdeas = activeIdeas;
        _archivedIdeas = archivedIdeas;
        _publishedIdeas = publishedIdeas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('アイデアの読み込みに失敗しました: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイデアランチャー'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'アクティブ'),
            Tab(text: '達成済み'),
            Tab(text: 'アーカイブ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIdeas,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIdeaList(_activeIdeas),
                _buildIdeaList(_publishedIdeas),
                _buildIdeaList(_archivedIdeas),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateIdeaDialog,
        child: const Icon(Icons.add),
        tooltip: '新しいアイデアを作成',
      ),
    );
  }

  Widget _buildIdeaList(List<Idea> ideas) {
    if (ideas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'アイデアがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateIdeaDialog,
              icon: const Icon(Icons.add),
              label: const Text('新しいアイデアを作成'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIdeas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index];
          return IdeaCard(
            idea: idea,
            onTap: () => _navigateToIdeaDetail(idea),
            onArchive: () => _archiveIdea(idea),
            onDelete: () => _deleteIdea(idea),
          );
        },
      ),
    );
  }

  void _navigateToIdeaDetail(Idea idea) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdeaDetailScreen(idea: idea),
      ),
    ).then((_) {
      _loadIdeas();
    });
  }

  Future<void> _archiveIdea(Idea idea) async {
    try {
      await _apiService.archiveIdea(idea.id);
      await _loadIdeas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${idea.title}をアーカイブしました')),
      );
    } catch (e) {
      _showErrorSnackBar('アーカイブに失敗しました: ${e.toString()}');
    }
  }

  Future<void> _deleteIdea(Idea idea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイデアを削除'),
        content: Text('${idea.title}を削除してもよろしいですか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteIdea(idea.id);
        await _loadIdeas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${idea.title}を削除しました')),
        );
      } catch (e) {
        _showErrorSnackBar('削除に失敗しました: ${e.toString()}');
      }
    }
  }

  Future<void> _showCreateIdeaDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final goalController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいアイデア'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: 'アイデアのタイトルを入力してください',
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'タイトルは必須です';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    hintText: 'アイデアの簡単な説明を入力してください',
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: goalController,
                  decoration: const InputDecoration(
                    labelText: 'ゴール (7日以内)',
                    hintText: '達成すべきゴールを入力 (50字以内)',
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ゴールは必須です';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠ 24時間アクションがない場合、または7日以内にゴール未達成の場合は削除されます。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              ],
            ),
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'goal': goalController.text.trim(),
                });
              }
            },
            child: const Text('作成して開始'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newIdea = await _apiService.createIdea(
          title: result['title'] ?? '',
          description: result['description'] ?? '',
          goal: result['goal'] ?? '',
        );

        if (context.mounted) {
          _navigateToIdeaDetail(newIdea);
        }
      } catch (e) {
        _showErrorSnackBar('アイデアの作成に失敗しました: ${e.toString()}');
      }
    }
  }
}