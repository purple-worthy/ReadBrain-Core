/// 配置服务接口（Domain 层核心抽象）
/// 定义所有配置相关的操作，不依赖具体实现
abstract class IConfigService {
  /// 初始化服务
  Future<void> initialize();

  /// 获取自动恢复状态
  Future<bool> getAutoRestore();

  /// 设置自动恢复状态
  /// [value] 是否自动恢复
  Future<void> setAutoRestore(bool value);

  /// 获取配置值
  /// [key] 配置键
  /// [defaultValue] 默认值
  Future<T?> getConfig<T>(String key, T? defaultValue);

  /// 设置配置值
  /// [key] 配置键
  /// [value] 配置值
  Future<void> setConfig<T>(String key, T value);

  /// 清除所有配置
  Future<void> clearAllConfig();
}
