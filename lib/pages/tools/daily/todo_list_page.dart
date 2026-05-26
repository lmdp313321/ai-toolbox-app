import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});
  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('todos');
    if (data != null) {
      setState(() => _todos = List<Map<String, dynamic>>.from(jsonDecode(data)));
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todos', jsonEncode(_todos));
  }

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _todos.insert(0, {'text': _controller.text.trim(), 'done': false});
      _controller.clear();
    });
    _saveTodos();
  }

  void _toggleTodo(int i) {
    setState(() => _todos[i]['done'] = !_todos[i]['done']);
    _saveTodos();
  }

  void _deleteTodo(int i) {
    setState(() => _todos.removeAt(i));
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待办清单')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '添加待办事项...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add_task),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addTodo, child: const Text('添加')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (ctx, i) {
                final todo = _todos[i];
                return ListTile(
                  leading: Checkbox(
                    value: todo['done'] as bool,
                    onChanged: (_) => _toggleTodo(i),
                  ),
                  title: Text(
                    todo['text'] as String,
                    style: TextStyle(
                      decoration: todo['done'] as bool ? TextDecoration.lineThrough : null,
                      color: todo['done'] as bool ? Colors.grey : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteTodo(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
