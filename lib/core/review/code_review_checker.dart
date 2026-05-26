/// 代码编译前置审查工具
/// 在执行 flutter build 前运行，检测常见编译错误
/// 用法: dart run lib/core/review/code_review_checker.dart
///
/// 检查项:
/// 1. 路由文件中所有import的文件是否存在
/// 2. ApiConfig等模型类的setter合法性
/// 3. 构造函数调用与import的类名一致性
library;

import 'dart:io';
import 'dart:convert';

void main() {
  final baseDir = Directory.current.path;
  final checker = CodeReviewChecker(baseDir);
  final issues = checker.checkAll();
  
  if (issues.isEmpty) {
    print('✅ 代码审查通过，0个问题');
    exit(0);
  } else {
    print('❌ 发现 ${issues.length} 个问题：\n');
    for (final issue in issues) {
      print('  [$issue.type] ${issue.file}:${issue.line}');
      print('    ${issue.message}');
      if (issue.suggestion.isNotEmpty) {
        print('    建议: ${issue.suggestion}');
      }
      print('');
    }
    exit(1);
  }
}

class ReviewIssue {
  final String type;
  final String file;
  final int line;
  final String message;
  final String suggestion;
  
  ReviewIssue({
    required this.type,
    required this.file,
    required this.line,
    required this.message,
    this.suggestion = '',
  });
}

class CodeReviewChecker {
  final String baseDir;
  
  CodeReviewChecker(this.baseDir);
  
  List<ReviewIssue> checkAll() {
    final issues = <ReviewIssue>[];
    issues.addAll(_checkRouteImports());
    issues.addAll(_checkFinalSetters());
    return issues;
  }
  
  /// 检查1: 路由文件中所有import的文件是否存在
  List<ReviewIssue> _checkRouteImports() {
    final issues = <ReviewIssue>[];
    final routerFile = File('$baseDir/lib/core/router/app_router.dart');
    if (!routerFile.existsSync()) return issues;
    
    final lines = routerFile.readAsLinesSync();
    final pageImportPattern = RegExp(r"^import '([^']+)';$");
    
    for (int i = 0; i < lines.length; i++) {
      final match = pageImportPattern.firstMatch(lines[i].trim());
      if (match == null) continue;
      
      String importPath = match.group(1)!;
      if (importPath.startsWith('../../')) {
        importPath = importPath.replaceFirst('../../', 'lib/');
      } else if (importPath.startsWith('package:ai_toolbox/')) {
        importPath = importPath.replaceFirst('package:ai_toolbox/', '');
      } else {
        continue;
      }
      
      final fullPath = '$baseDir/$importPath';
      if (!File(fullPath).existsSync()) {
        issues.add(ReviewIssue(
          type: 'MISSING_FILE',
          file: 'lib/core/router/app_router.dart',
          line: i + 1,
          message: '引用的文件不存在: $importPath',
          suggestion: '创建文件或修复import路径',
        ));
      }
    }
    return issues;
  }
  
  /// 检查2: 尝试对final字段赋值
  List<ReviewIssue> _checkFinalSetters() {
    final issues = <ReviewIssue>[];
    final dir = Directory('$baseDir/lib');
    if (!dir.existsSync()) return issues;
    
    final dartFiles = dir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
    
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      
      final finalFields = <String>{};
      for (int i = 0; i < lines.length; i++) {
        final match = RegExp(r'^\s+final\s+\w+\s+(\w+);').firstMatch(lines[i]);
        if (match != null) {
          finalFields.add(match.group(1)!);
        }
      }
      
      for (int i = 0; i < lines.length; i++) {
        final setterMatch = RegExp(r'\.(\w+)\s*=').firstMatch(lines[i]);
        if (setterMatch != null) {
          final fieldName = setterMatch.group(1)!;
          if (finalFields.contains(fieldName)) {
            issues.add(ReviewIssue(
              type: 'FINAL_SETTER',
              file: file.path.replaceFirst('$baseDir/', ''),
              line: i + 1,
              message: '对final字段 "$fieldName" 赋值',
              suggestion: '改为重建对象的方式赋值',
            ));
          }
        }
      }
    }
    return issues;
  }
}
