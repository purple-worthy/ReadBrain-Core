import 'package:get_it/get_it.dart';
import '../domain/interfaces/i_storage_service.dart';
import '../domain/interfaces/i_config_service.dart';
import '../domain/interfaces/i_book_service.dart';
import '../domain/interfaces/i_reader_engine.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/config_service.dart';
import '../data/services/book_service.dart';
import '../data/services/mock_reader_engine.dart';

/// 服务定位器（Service Locator）
/// 使用 GetIt 实现依赖注入，统一管理所有服务的注册和获取
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// 初始化所有服务
  /// 在应用启动时调用，注册所有服务单例
  static Future<void> setup() async {
    // 注册存储服务（单例）
    _getIt.registerSingletonAsync<IStorageService>(
      () async {
        final service = LocalStorageService();
        await service.initialize();
        return service;
      },
    );

    // 注册配置服务（单例）
    _getIt.registerSingletonAsync<IConfigService>(
      () async {
        final service = ConfigService();
        await service.initialize();
        return service;
      },
    );

    // 注册书籍服务（单例）
    _getIt.registerSingletonAsync<IBookService>(
      () async {
        final service = BookService();
        await service.initialize();
        return service;
      },
    );

    // 注册阅读引擎（单例）
    // 注意：这里可以轻松切换不同的引擎实现
    // 例如：如果要切换到大模型解析引擎，只需要修改这里的注册代码
    _getIt.registerSingletonAsync<IReaderEngine>(
      () async {
        // 当前使用模拟引擎，后续可以替换为 PDFEngine 或其他实现
        final service = MockReaderEngine();
        await service.initialize();
        return service;
      },
    );

    // 等待所有异步服务初始化完成
    await _getIt.allReady();
  }

  /// 获取服务实例
  /// [T] 服务类型
  static T get<T extends Object>() {
    return _getIt.get<T>();
  }

  /// 检查服务是否已注册
  /// [T] 服务类型
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }

  /// 重置所有服务（主要用于测试）
  static Future<void> reset() async {
    await _getIt.reset();
  }
}
