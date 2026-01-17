import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/interfaces/i_storage_service.dart';

/// 优化版本地存储服务实现
class LocalStorageService implements IStorageService {
  late final SharedPreferences _prefs;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _ready = true;
    } catch (e) {
      debugPrint('LocalStorage 初始化崩了: $e');
    }
  }

  // 内部辅助方法：减少重复的 try-catch 和判断
  Future<bool> _safeSave(Future<bool> Function() action, String key) async {
    if (!_ready) return false;
    try {
      return await action();
    } catch (e) {
      debugPrint('存储失败 [Key: $key]: $e');
      return false;
    }
  }

  // --- 接口实现 ---
  @override
  Future<bool> saveStringList(String key, List<String> value) => 
      _safeSave(() => _prefs.setStringList(key, value), key);

  @override
  Future<List<String>?> getStringList(String key) async => _ready ? _prefs.getStringList(key) : null;

  @override
  Future<bool> saveInt(String key, int value) => 
      _safeSave(() => _prefs.setInt(key, value), key);

  @override
  Future<int?> getInt(String key) async => _ready ? _prefs.getInt(key) : null;

  @override
  Future<bool> saveBool(String key, bool value) => 
      _safeSave(() => _prefs.setBool(key, value), key);

  @override
  Future<bool?> getBool(String key) async => _ready ? _prefs.getBool(key) : null;

  @override
  Future<bool> saveString(String key, String value) => 
      _safeSave(() => _prefs.setString(key, value), key);

  @override
  Future<String?> getString(String key) async => _ready ? _prefs.getString(key) : null;

  @override
  Future<bool> remove(String key) => _safeSave(() => _prefs.remove(key), key);

  @override
  Future<bool> clear() => _safeSave(() => _prefs.clear(), 'ALL');
  
}