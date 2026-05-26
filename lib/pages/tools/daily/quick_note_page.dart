import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuickNotePage extends StatefulWidget {
  const QuickNotePage({super.key});
  @override
  State<QuickNotePage> createState() => _QuickNotePageState();
}

class _QuickNotePageState extends State<QuickNotePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('quick_notes');
    if (data != null) {
      setState(() => _notes = List<String>.from(jsonDecode(data)));
    }
  }

  Future<void> _saveNote() async {
    if (_controller.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _notes.insert(0, _controller.text.trim());
    if (_notes.length > 50) _notes = _notes.sublist(0, 50);
    await prefs.setString('quick_notes', jsonEncode(_notes));
    _controller.clear();
    setState(() {});
  }

  Future<void> _deleteNote(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _notes.removeAt(index);
    await prefs.setString('quick_notes', jsonEncode(_notes));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('速记')),
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
                      hintText: '输入内容，打开即写...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _saveNote,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (ctx, i) => Dismissible(
                key: Key(_notes[i]),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteNote(i),
                child: ListTile(
                  title: Text(_notes[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteNote(i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
