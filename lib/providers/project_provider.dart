import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/models/project_models.dart';
import 'package:app/models/lego_models.dart' as lego_models;
import 'package:app/services/project_service.dart';
import 'package:file_picker/file_picker.dart';
// 鸿蒙平台文件选择器
import 'package:file_picker_ohos/file_picker_ohos.dart' as ohos_picker;

/// 项目管理状态数据模型
class ProjectState {
  final List<ProjectData> projects;
  final ProjectSortMode sortMode;
  final ProjectViewMode viewMode;
  final bool isLoading;
  final String? error;
  final ProjectData? selectedProject;
  final bool isImporting;
  final bool isExporting;

  const ProjectState({
    this.projects = const [],
    this.sortMode = ProjectSortMode.dateUpdated,
    this.viewMode = ProjectViewMode.grid,
    this.isLoading = false,
    this.error,
    this.selectedProject,
    this.isImporting = false,
    this.isExporting = false,
  });

  ProjectState copyWith({
    List<ProjectData>? projects,
    ProjectSortMode? sortMode,
    ProjectViewMode? viewMode,
    bool? isLoading,
    String? error,
    ProjectData? selectedProject,
    bool? isImporting,
    bool? isExporting,
    bool clearSelectedProject = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      sortMode: sortMode ?? this.sortMode,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedProject: clearSelectedProject ? null : (selectedProject ?? this.selectedProject),
      isImporting: isImporting ?? this.isImporting,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  List<ProjectData> get sortedProjects {
    final projectsList = List<ProjectData>.from(projects);
    
    switch (sortMode) {
      case ProjectSortMode.name:
        projectsList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProjectSortMode.dateCreated:
        projectsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProjectSortMode.dateUpdated:
        projectsList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ProjectSortMode.brickCount:
        projectsList.sort((a, b) => b.brickCount.compareTo(a.brickCount));
        break;
    }
    
    return projectsList;
  }
}

/// 项目管理状态管理器
class ProjectNotifier extends StateNotifier<ProjectState> {
  final ProjectService _projectService = ProjectService();
  
  ProjectNotifier() : super(const ProjectState()) {
    _initProjects();
  }
  
  // 判断是否为鸿蒙平台
  bool get _isOhosplatform {
    try {
      return Platform.operatingSystem == 'ohos';
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _initProjects() async {
    await _projectService.init();
    await loadProjects();
  }
  
  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final projects = await _projectService.getAllProjects();
      state = state.copyWith(
        projects: projects,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载项目失败: $e',
      );
    }
  }
  
  Future<void> refreshProjects() async {
    await loadProjects();
  }
  
  Future<void> deleteProject(String projectId) async {
    try {
      final success = await _projectService.deleteProject(projectId);
      if (success) {
        final updatedProjects = state.projects
            .where((project) => project.id != projectId)
            .toList();
        
        state = state.copyWith(
          projects: updatedProjects,
          selectedProject: state.selectedProject?.id == projectId ? null : state.selectedProject,
        );
      } else {
        state = state.copyWith(error: '删除项目失败');
      }
    } catch (e) {
      state = state.copyWith(error: '删除项目失败: $e');
    }
  }
  
  Future<void> selectProject(ProjectData project) async {
    state = state.copyWith(selectedProject: project);
  }
  
  Future<void> clearSelectedProject() async {
    state = state.copyWith(clearSelectedProject: true);
  }
  
  Future<void> setSortMode(ProjectSortMode mode) async {
    state = state.copyWith(sortMode: mode);
  }
  
  Future<void> setViewMode(ProjectViewMode mode) async {
    state = state.copyWith(viewMode: mode);
  }
  
  Future<bool> exportProject(String projectId) async {
    state = state.copyWith(isExporting: true);
    
    try {
      // 根据平台选择不同的文件选择器并直接处理
      if (_isOhosplatform) {
        // 鸿蒙平台使用 file_picker_ohos
        final result = await ohos_picker.FilePicker.platform.saveFile(
          dialogTitle: '导出项目',
          fileName: 'lego_project_$projectId.json',
          type: ohos_picker.FileType.custom,
          allowedExtensions: ['json'],
        );
        
        if (result != null) {
          final success = await _projectService.exportProjectAsJson(projectId, result);
          state = state.copyWith(isExporting: false);
          return success;
        }
      } else {
        // 其他平台使用标准 file_picker
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '导出项目',
          fileName: 'lego_project_$projectId.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        
        if (result != null) {
          final success = await _projectService.exportProjectAsJson(projectId, result);
          state = state.copyWith(isExporting: false);
          return success;
        }
      }
      
      state = state.copyWith(isExporting: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: '导出失败: $e',
      );
      return false;
    }
  }
  
  Future<bool> updateProject(String projectId, {
    String? name,
    String? description,
    List<lego_models.BrickData>? bricks,
    List<String>? tags,
  }) async {
    try {
      final success = await _projectService.updateProject(
        projectId,
        name: name,
        description: description,
        bricks: bricks,
        tags: tags,
      );
      
      if (success) {
        // 重新加载项目列表
        await loadProjects();
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(error: '更新项目失败: $e');
      return false;
    }
  }
  
  Future<ProjectData?> importProject() async {
    state = state.copyWith(isImporting: true);
    
    try {
      // 根据平台选择不同的文件选择器并直接处理
      if (_isOhosplatform) {
        // 鸿蒙平台使用 file_picker_ohos
        final result = await ohos_picker.FilePicker.platform.pickFiles(
          dialogTitle: '导入项目',
          type: ohos_picker.FileType.custom,
          allowedExtensions: ['json'],
        );
        
        if (result != null && result.files.isNotEmpty) {
          final filePath = result.files.first.path!;
          final project = await _projectService.importProjectFromJson(filePath);
          
          if (project != null) {
            final updatedProjects = [...state.projects, project];
            state = state.copyWith(
              projects: updatedProjects,
              isImporting: false,
            );
            return project;
          }
        }
      } else {
        // 其他平台使用标准 file_picker
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: '导入项目',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        
        if (result != null && result.files.isNotEmpty) {
          final filePath = result.files.first.path!;
          final project = await _projectService.importProjectFromJson(filePath);
          
          if (project != null) {
            final updatedProjects = [...state.projects, project];
            state = state.copyWith(
              projects: updatedProjects,
              isImporting: false,
            );
            return project;
          }
        }
      }
      
      state = state.copyWith(isImporting: false);
      return null;
    } catch (e) {
      // 导入失败不设置error，由页面的SnackBar显示
      state = state.copyWith(isImporting: false);
      return null;
    }
  }
  
  Future<void> clearError() async {
    state = state.copyWith(error: null);
  }
}

// Providers
final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier();
});

final projectNotifierProvider = Provider<ProjectNotifier>((ref) {
  return ref.watch(projectProvider.notifier);
});

// 搜索和过滤功能
final searchQueryProvider = StateProvider<String>((ref) => '');
final filteredProjectsProvider = Provider<List<ProjectData>>((ref) {
  final projects = ref.watch(projectProvider).sortedProjects;
  final searchQuery = ref.watch(searchQueryProvider);
  
  if (searchQuery.isEmpty) {
    return projects;
  }
  
  return projects.where((project) {
    return project.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
           project.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
           project.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
  }).toList();
});
