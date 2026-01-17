import 'package:flutter/foundation.dart';
import '../../domain/interfaces/i_config_service.dart';
import '../../domain/interfaces/i_storage_service.dart';
import '../../core/service_locator.dart';

/// 配置服务实现（Data 层）
/// 实现 IConfigService 接口，负责应用配置的管理
class ConfigService implements IConfigService {
  // 存储服务（通过依赖注入获取）
  late final IStorageService _storageService;

  // 配置键常量
  static const String _keyAutoRestore = 'auto_restore';
  static const String _keyPrefix = 'config_';

  // 自动恢复状态缓存
  bool _autoRestore = true;

  // 自动恢复状态通知器（用于 UI 绑定）
  final ValueNotifier<bool> autoRestoreNotifier = ValueNotifier<bool>(true);

  ConfigService() {
    // 从服务定位器获取存储服务
    _storageService = ServiceLocator.get<IStorageService>();
  }

  @override
  Future<void> initialize() async {
    try {
      // 加载自动恢复设置
      final savedAutoRestore = await _storageService.getBool(_keyAutoRestore);
      _autoRestore = savedAutoRestore ?? true;
      autoRestoreNotifier.value = _autoRestore;
    } catch (e) {
      debugPrint('ConfigService 初始化失败: $e');
    }
  }

  @override
  Future<bool> getAutoRestore() async {
    return _autoRestore;
  }

  @override
  Future<void> setAutoRestore(bool value) async {
    try {
      _autoRestore = value;
      autoRestoreNotifier.value = value;
      await _storageService.saveBool(_keyAutoRestore, value);
    } catch (e) {
      debugPrint('设置自动恢复状态失败: $e');
    }
  }

  @override
  Future<T?> getConfig<T>(String key, T? defaultValue) async {
    try {
      final fullKey = '$_keyPrefix$key';
      
      if (T == bool) {
        final value = await _storageService.getBool(fullKey);
        return (value ?? defaultValue) as T?;
      } else if (T == int) {
        final value = await _storageService.getInt(fullKey);
        return (value ?? defaultValue) as T?;
      } else if (T == String) {
        final value = await _storageService.getString(fullKey);
        return (value ?? defaultValue) as T?;
      } else {
        debugPrint('不支持的配置类型: $T');
        return defaultValue;
      }
    } catch (e) {
      debugPrint('获取配置失败 [$key]: $e');
      return defaultValue;
    }
  }

  @override
  Future<void> setConfig<T>(String key, T value) async {
    try {
      final fullKey = '$_keyPrefix$key';
      
      if (T == bool && value is bool) {
        await _storageService.saveBool(fullKey, value);
      } else if (T == int && value is int) {
        await _storageService.saveInt(fullKey, value);
      } else if (T == String && value is String) {
        await _storageService.saveString(fullKey, value);
      } else {
        debugPrint('不支持的配置类型: $T');
      }
    } catch (e) {
      debugPrint('设置配置失败 [$key]: $e');
    }
  }

  @override
  Future<void> clearAllConfig() async {
    try {
      // 注意：这里只清除配置相关的键，不清除其他数据
      // 如果需要清除所有配置，需要遍历所有配置键
      await _storageService.remove(_keyAutoRestore);
      _autoRestore = true;
      autoRestoreNotifier.value = true;
    } catch (e) {
      debugPrint('清除所有配置失败: $e');
    }
  }
}
