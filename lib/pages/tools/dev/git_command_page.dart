import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Git命令查询页面 - 常用Git命令速查
class GitCommandPage extends StatefulWidget {
  const GitCommandPage({super.key});

  @override
  State<GitCommandPage> createState() => _GitCommandPageState();
}

class _GitCommandPageState extends State<GitCommandPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _gitCommands = [
    {
      'category': '配置',
      'commands': [
        {'cmd': 'git config --global user.name "名字"', 'desc': '设置全局用户名'},
        {'cmd': 'git config --global user.email "邮箱"', 'desc': '设置全局邮箱'},
        {'cmd': 'git config --list', 'desc': '查看所有配置'},
      ],
    },
    {
      'category': '仓库操作',
      'commands': [
        {'cmd': 'git init', 'desc': '初始化本地仓库'},
        {'cmd': 'git clone <url>', 'desc': '克隆远程仓库'},
        {'cmd': 'git status', 'desc': '查看工作区状态'},
        {'cmd': 'git remote -v', 'desc': '查看远程仓库地址'},
        {'cmd': 'git remote add origin <url>', 'desc': '添加远程仓库'},
      ],
    },
    {
      'category': '基本操作',
      'commands': [
        {'cmd': 'git add <file>', 'desc': '添加文件到暂存区'},
        {'cmd': 'git add .', 'desc': '添加所有改动到暂存区'},
        {'cmd': 'git commit -m "message"', 'desc': '提交暂存区的改动'},
        {'cmd': 'git commit -am "message"', 'desc': '添加并提交所有改动'},
      ],
    },
    {
      'category': '分支操作',
      'commands': [
        {'cmd': 'git branch', 'desc': '查看本地分支'},
        {'cmd': 'git branch -a', 'desc': '查看所有分支'},
        {'cmd': 'git branch <name>', 'desc': '创建新分支'},
        {'cmd': 'git checkout <branch>', 'desc': '切换到指定分支'},
        {'cmd': 'git checkout -b <name>', 'desc': '创建并切换分支'},
        {'cmd': 'git merge <branch>', 'desc': '合并指定分支到当前分支'},
        {'cmd': 'git branch -d <name>', 'desc': '删除本地分支'},
      ],
    },
    {
      'category': '远程同步',
      'commands': [
        {'cmd': 'git pull', 'desc': '拉取远程代码并合并'},
        {'cmd': 'git pull origin main', 'desc': '拉取指定分支'},
        {'cmd': 'git push', 'desc': '推送本地代码到远程'},
        {'cmd': 'git push origin <branch>', 'desc': '推送到指定分支'},
        {'cmd': 'git push -u origin main', 'desc': '首次推送并关联分支'},
        {'cmd': 'git fetch', 'desc': '获取远程分支信息'},
      ],
    },
    {
      'category': '撤销操作',
      'commands': [
        {'cmd': 'git reset HEAD <file>', 'desc': '取消暂存文件'},
        {'cmd': 'git checkout -- <file>', 'desc': '撤销文件修改'},
        {'cmd': 'git reset --hard HEAD~1', 'desc': '回退到上一个版本'},
        {'cmd': 'git revert <commit>', 'desc': '撤销指定提交'},
      ],
    },
    {
      'category': '查看历史',
      'commands': [
        {'cmd': 'git log', 'desc': '查看提交历史'},
        {'cmd': 'git log --oneline', 'desc': '简洁显示提交历史'},
        {'cmd': 'git log --graph', 'desc': '图形化显示分支历史'},
        {'cmd': 'git diff', 'desc': '查看工作区与暂存区差异'},
        {'cmd': 'git diff --cached', 'desc': '查看暂存区与仓库差异'},
      ],
    },
    {
      'category': '标签操作',
      'commands': [
        {'cmd': 'git tag', 'desc': '查看所有标签'},
        {'cmd': 'git tag <name>', 'desc': '创建轻量标签'},
        {'cmd': 'git tag -a <name> -m "msg"', 'desc': '创建附注标签'},
        {'cmd': 'git push origin --tags', 'desc': '推送所有标签到远程'},
      ],
    },
    {
      'category': '储藏操作',
      'commands': [
        {'cmd': 'git stash', 'desc': '储藏当前修改'},
        {'cmd': 'git stash list', 'desc': '查看储藏列表'},
        {'cmd': 'git stash pop', 'desc': '恢复最近一次储藏'},
        {'cmd': 'git stash apply', 'desc': '应用储藏但不删除'},
        {'cmd': 'git stash drop', 'desc': '删除最近一次储藏'},
      ],
    },
    {
      'category': '高级操作',
      'commands': [
        {'cmd': 'git rebase <branch>', 'desc': '变基操作'},
        {'cmd': 'git cherry-pick <commit>', 'desc': '拣选指定提交'},
        {'cmd': 'git bisect start', 'desc': '二分查找问题提交'},
        {'cmd': 'git reflog', 'desc': '查看所有操作记录'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredCommands {
    if (_searchQuery.isEmpty) return _gitCommands;
    
    return _gitCommands.map((category) {
      final filteredCmds = (category['commands'] as List).where((cmd) {
        return cmd['cmd'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
               cmd['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      
      return {
        'category': category['category'],
        'commands': filteredCmds,
      };
    }).where((cat) => (cat['commands'] as List).isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Git命令速查'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索命令',
                hintText: '输入关键字搜索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          
          // 命令列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCommands.length,
              itemBuilder: (context, index) => _buildCategoryCard(_filteredCommands[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          category['category'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: _searchQuery.isNotEmpty,
        children: (category['commands'] as List).map<Widget>((cmd) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      cmd['cmd'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cmd['cmd']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已复制: ${cmd['cmd']}')),
                      );
                    },
                  ),
                ],
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(cmd['desc']),
            ),
          );
        }).toList(),
      ),
    );
  }
}
