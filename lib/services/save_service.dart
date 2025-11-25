import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:app/models/lego_models.dart';

/// 积木保存服务类
/// 负责处理积木数据的保存、加载、文件管理等操作
class SaveService {
  /// 保存积木数据为JSON文件
  static Future<String> saveBricksToJson(List<BrickData> bricks, {String? fileName}) async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final savePath = Directory('${directory.path}/lego_saves');
      
      // 确保保存目录存在
      if (!await savePath.exists()) {
        await savePath.create(recursive: true);
      }
      
      // 生成文件名（使用时间戳）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'lego_build_$timestamp';
      final file = File('${savePath.path}/$name.json');
      
      // 转换为JSON
      final jsonData = {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'brickCount': bricks.length,
        'bricks': bricks.map((brick) => brick.toJson()).toList(),
      };
      
      // 写入文件
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );
      
      return file.path;
    } catch (e) {
      throw Exception('保存失败: $e');
    }
  }
  
  /// 从JSON文件加载积木数据
  static Future<List<BrickData>> loadBricksFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final bricksList = jsonData['bricks'] as List;
      return bricksList.map((brick) => BrickData.fromJson(brick)).toList();
    } catch (e) {
      throw Exception('加载失败: $e');
    }
  }
  
  /// 获取所有保存的文件列表
  static Future<List<File>> getSavedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final savePath = Directory('${directory.path}/lego_saves');
      
      if (!await savePath.exists()) {
        return [];
      }
      
      final files = savePath
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      // 按修改时间排序（最新的在前）
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      return [];
    }
  }
  
  /// 删除保存的文件
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }
  
  /// 获取文件信息
  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }
      
      final stat = await file.stat();
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return {
        'path': filePath,
        'name': file.uri.pathSegments.last,
        'size': stat.size,
        'modified': stat.modified,
        'brickCount': jsonData['brickCount'] ?? 0,
        'createdAt': jsonData['createdAt'],
      };
    } catch (e) {
      throw Exception('获取文件信息失败: $e');
    }
  }
}
