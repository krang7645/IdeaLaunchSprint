import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(bool?) onToggle;
  final VoidCallback? onDelete;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.onToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        if (onDelete != null) onDelete!();
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Checkbox(
                value: todo.done,
                onChanged: onToggle,
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.done ? TextDecoration.lineThrough : null,
                        color: todo.done ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (todo.dueDate != null)
                      Text(
                        '期限: ${DateFormat('yyyy/MM/dd').format(todo.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDueDateOverdue(todo.dueDate) && !todo.done
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDueDateOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(dueDate) &&
           !(now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day);
  }
}