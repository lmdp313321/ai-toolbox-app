import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/config/tool_config.dart';

class ToolProvider extends ChangeNotifier {
  static const String _hiddenToolsKey = 'hidden_tools';
  
  Set<String> _hiddenTools = {};
  Set<String> get hiddenTools => _hiddenTools;
  
  Map<String, int> _toolOrder = {};
  
  ToolProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenList = prefs.getStringList(_hiddenToolsKey) ?? [];
    _hiddenTools = hiddenList.toSet();
    notifyListeners();
  }
  
  Future<void> toggleToolVisibility(String toolId) async {
    if (_hiddenTools.contains(toolId)) {
      _hiddenTools.remove(toolId);
    } else {
      _hiddenTools.add(toolId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenToolsKey, _hiddenTools.toList());
    notifyListeners();
  }
  
  bool isToolVisible(String toolId) {
    return !_hiddenTools.contains(toolId);
  }
  
  List<Map<String, dynamic>> getVisibleToolsByCategory(String categoryId) {
    return ToolConfig.tools
        .where((tool) => 
            tool['categoryId'] == categoryId && 
            !_hiddenTools.contains(tool['id']) &&
            tool['enabled'] == true)
        .toList()
      ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
  }
  
  List<Map<String, dynamic>> get allTools => ToolConfig.tools;
  
  List<Map<String, dynamic>> get allCategories => ToolConfig.categories;
}
