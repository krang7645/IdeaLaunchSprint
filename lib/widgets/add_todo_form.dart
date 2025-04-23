import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTodoForm extends StatefulWidget {
  final Function(String title, DateTime? dueDate) onSubmit;

  const AddTodoForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddTodoForm> createState() => _AddTodoFormState();
}

class _AddTodoFormState extends State<AddTodoForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_titleController.text, _selectedDate);
      _titleController.clear();
      setState(() {
        _selectedDate = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('ja', 'JP'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タスク内容',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'タスク内容を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '期限日（任意）',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? '期限日を選択'
                          : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('タスクを追加'),
          ),
        ],
      ),
    );
  }
}