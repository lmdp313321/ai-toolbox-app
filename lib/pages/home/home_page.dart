import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/tool_config.dart';
import '../../providers/tool_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final toolProvider = Provider.of<ToolProvider>(context);
    final categories = toolProvider.allCategories;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI工具箱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _buildBody(categories[_currentIndex]['id']),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: categories.map((cat) => NavigationDestination(
          icon: Text(cat['icon'] as String, style: const TextStyle(fontSize: 24)),
          selectedIcon: Text(cat['icon'] as String, style: const TextStyle(fontSize: 24)),
          label: cat['name'] as String,
        )).toList(),
      ),
    );
  }
  
  Widget _buildBody(String categoryId) {
    final toolProvider = Provider.of<ToolProvider>(context);
    final tools = toolProvider.getVisibleToolsByCategory(categoryId);
    
    if (tools.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无工具', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _ToolCard(
          icon: tool['icon'] as String,
          name: tool['name'] as String,
          description: tool['description'] as String,
          onTap: () => Navigator.pushNamed(context, tool['route'] as String),
        );
      },
    );
  }
  
  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ToolSearchDelegate(),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final VoidCallback onTap;
  
  const _ToolCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ToolSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    final results = ToolConfig.tools
        .where((t) => 
            (t['name'] as String).contains(query) ||
            (t['description'] as String).contains(query))
        .toList();
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final tool = results[index];
        return ListTile(
          leading: Text(tool['icon'] as String, style: const TextStyle(fontSize: 24)),
          title: Text(tool['name'] as String),
          subtitle: Text(tool['description'] as String),
          onTap: () {
            close(context, null);
            Navigator.pushNamed(context, tool['route'] as String);
          },
        );
      },
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
