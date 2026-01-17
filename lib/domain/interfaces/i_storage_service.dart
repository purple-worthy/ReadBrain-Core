/// 存储服务接口（Domain 层核心抽象）
/// 定义数据持久化的抽象操作，不依赖具体的存储实现
abstract class IStorageService {
  /// 初始化服务
  Future<void> initialize();

  /// 保存字符串列表
  /// [key] 存储键
  /// [value] 字符串列表
  Future<bool> saveStringList(String key, List<String> value);

  /// 读取字符串列表
  /// [key] 存储键
  /// [defaultValue] 默认值
  Future<List<String>?> getStringList(String key);

  /// 保存整数
  /// [key] 存储键
  /// [value] 整数值
  Future<bool> saveInt(String key, int value);

  /// 读取整数
  /// [key] 存储键
  /// [defaultValue] 默认值
  Future<int?> getInt(String key);

  /// 保存布尔值
  /// [key] 存储键
  /// [value] 布尔值
  Future<bool> saveBool(String key, bool value);

  /// 读取布尔值
  /// [key] 存储键
  /// [defaultValue] 默认值
  Future<bool?> getBool(String key);

  /// 保存字符串
  /// [key] 存储键
  /// [value] 字符串值
  Future<bool> saveString(String key, String value);

  /// 读取字符串
  /// [key] 存储键
  /// [defaultValue] 默认值
  Future<String?> getString(String key);

  /// 清除指定键的数据
  /// [key] 存储键
  Future<bool> remove(String key);

  /// 清除所有数据
  Future<bool> clear();
}
