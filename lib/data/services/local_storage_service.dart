import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/interfaces/i_storage_service.dart';

/// 本地存储服务实现（Data 层）
/// 基于 shared_preferences 的具体实现
class LocalStorageService implements IStorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // 初始化失败时记录错误，但不抛出异常，允许应用继续运行
      debugPrint('LocalStorageService 初始化失败: $e');
    }
  }

  /// 检查 SharedPreferences 是否已初始化
  bool get _isInitialized => _prefs != null;

  @override
  Future<bool> saveStringList(String key, List<String> value) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法保存数据: $key');
      return false;
    }
    try {
      return await _prefs!.setStringList(key, value);
    } catch (e) {
      debugPrint('保存字符串列表失败 [$key]: $e');
      return false;
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法读取数据: $key');
      return null;
    }
    try {
      return _prefs!.getStringList(key);
    } catch (e) {
      debugPrint('读取字符串列表失败 [$key]: $e');
      return null;
    }
  }

  @override
  Future<bool> saveInt(String key, int value) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法保存数据: $key');
      return false;
    }
    try {
      return await _prefs!.setInt(key, value);
    } catch (e) {
      debugPrint('保存整数失败 [$key]: $e');
      return false;
    }
  }

  @override
  Future<int?> getInt(String key) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法读取数据: $key');
      return null;
    }
    try {
      return _prefs!.getInt(key);
    } catch (e) {
      debugPrint('读取整数失败 [$key]: $e');
      return null;
    }
  }

  @override
  Future<bool> saveBool(String key, bool value) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法保存数据: $key');
      return false;
    }
    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      debugPrint('保存布尔值失败 [$key]: $e');
      return false;
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法读取数据: $key');
      return null;
    }
    try {
      return _prefs!.getBool(key);
    } catch (e) {
      debugPrint('读取布尔值失败 [$key]: $e');
      return null;
    }
  }

  @override
  Future<bool> saveString(String key, String value) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法保存数据: $key');
      return false;
    }
    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      debugPrint('保存字符串失败 [$key]: $e');
      return false;
    }
  }

  @override
  Future<String?> getString(String key) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法读取数据: $key');
      return null;
    }
    try {
      return _prefs!.getString(key);
    } catch (e) {
      debugPrint('读取字符串失败 [$key]: $e');
      return null;
    }
  }

  @override
  Future<bool> remove(String key) async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法删除数据: $key');
      return false;
    }
    try {
      return await _prefs!.remove(key);
    } catch (e) {
      debugPrint('删除数据失败 [$key]: $e');
      return false;
    }
  }

  @override
  Future<bool> clear() async {
    if (!_isInitialized) {
      debugPrint('LocalStorageService 未初始化，无法清除数据');
      return false;
    }
    try {
      return await _prefs!.clear();
    } catch (e) {
      debugPrint('清除所有数据失败: $e');
      return false;
    }
  }
}
