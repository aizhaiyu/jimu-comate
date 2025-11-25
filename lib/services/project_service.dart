import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:app/models/project_models.dart';
import 'package:app/models/lego_models.dart' as lego_models;

/// 项目管理服务类
/// 负责处理积木项目的增删改查、导入导出等操作
class ProjectService {
  static const String _projectsFolder = 'lego_projects';
  static const String _projectFileExtension = '.json';
  
  late Directory _projectsDir;
  
  /// 初始化服务，创建项目存储目录
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _projectsDir = Directory('${appDir.path}/$_projectsFolder');
    
    if (!await _projectsDir.exists()) {
      await _projectsDir.create(recursive: true);
    }
  }
  
  /// 获取所有项目列表，按更新时间降序排列
  Future<List<ProjectData>> getAllProjects() async {
    try {
      final files = await _projectsDir.list().where(
        (entity) => entity is File && entity.path.endsWith(_projectFileExtension),
      ).cast<File>().toList();
      
      final projects = <ProjectData>[];
      
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final project = ProjectData.fromJson(json);
          projects.add(project);
        } catch (e) {
          print('加载项目失败: ${file.path} - $e');
        }
      }
      
      // 按更新时间降序排列
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return projects;
    } catch (e) {
      print('获取项目列表失败: $e');
      return [];
    }
  }
  
  /// 根据ID获取单个项目
  Future<ProjectData?> getProjectById(String id) async {
    try {
      final file = File('${_projectsDir.path}/$id$_projectFileExtension');
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ProjectData.fromJson(json);
    } catch (e) {
      print('获取项目失败: $id - $e');
      return null;
    }
  }
  
  /// 保存项目到本地文件
  Future<bool> saveProject(ProjectData project) async {
    try {
      final file = File('${_projectsDir.path}/${project.id}$_projectFileExtension');
      final json = project.toJson();
      final content = const JsonEncoder.withIndent('  ').convert(json);
      
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('保存项目失败: ${project.id} - $e');
      return false;
    }
  }
  
  /// 删除指定项目
  Future<bool> deleteProject(String id) async {
    try {
      final file = File('${_projectsDir.path}/$id$_projectFileExtension');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除项目失败: $id - $e');
      return false;
    }
  }
  
  /// 更新项目信息
  Future<bool> updateProject(String id, {
    String? name,
    String? description,
    List<lego_models.BrickData>? bricks,
    List<String>? tags,
  }) async {
    try {
      final project = await getProjectById(id);
      if (project == null) {
        return false;
      }
      
      final updatedProject = project.copyWith(
        name: name,
        description: description,
        bricks: bricks,
        tags: tags,
        updatedAt: DateTime.now(),
        brickCount: bricks?.length ?? project.brickCount,
      );
      
      return await saveProject(updatedProject);
    } catch (e) {
      print('更新项目失败: $id - $e');
      return false;
    }
  }
  
  /// 导出项目为JSON文件
  Future<bool> exportProjectAsJson(String id, String exportPath) async {
    try {
      final project = await getProjectById(id);
      if (project == null) {
        return false;
      }
      
      final json = project.toJson();
      final content = const JsonEncoder.withIndent('  ').convert(json);
      
      final file = File(exportPath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('导出项目失败: $id - $e');
      return false;
    }
  }
  
  /// 从JSON文件导入项目
  Future<ProjectData?> importProjectFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // 生成新的ID和更新时间
      final projectData = Map<String, dynamic>.from(json);
      projectData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      projectData['updatedAt'] = DateTime.now().toIso8601String();
      projectData['createdAt'] = DateTime.now().toIso8601String();
      
      final project = ProjectData.fromJson(projectData);
      
      // 保存到本地
      if (await saveProject(project)) {
        return project;
      }
      
      return null;
    } catch (e) {
      print('导入项目失败: $filePath - $e');
      return null;
    }
  }
  
  /// 获取项目总数
  Future<int> getProjectsCount() async {
    try {
      final files = await _projectsDir.list().where(
        (entity) => entity is File && entity.path.endsWith(_projectFileExtension),
      ).cast<File>().toList();
      
      return files.length;
    } catch (e) {
      print('获取项目数量失败: $e');
      return 0;
    }
  }
}
