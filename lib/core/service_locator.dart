import 'package:get_it/get_it.dart';
import '../domain/interfaces/i_storage_service.dart';
import '../domain/interfaces/i_config_service.dart';
import '../domain/interfaces/i_book_service.dart';
import '../domain/interfaces/i_reader_engine.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/config_service.dart';
import '../data/services/book_service.dart'; // 指向你融合后的 BookService
import '../data/services/pdf_reader_engine.dart'; // 指向我们修好的 2.1.0 引擎

/// 终极组装中心（Service Locator）
/// 融合了异步安全启动与强依赖管理
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;


  static Future<void> setup() async {
    // 1. 优先注册基础存储服务（所有人的基石）
    _getIt.registerSingletonAsync<IStorageService>(() async {
      final service = LocalStorageService();
      await service.initialize();
      return service;
    });

    // 2. 注册阅读引擎（独立硬件级服务）
    _getIt.registerSingletonAsync<IReaderEngine>(() async {
      final service = PdfReaderEngine();
      await service.initialize();
      return service;
    });

    // 3. 注册配置服务（依赖 Storage）
    // 使用 dependsOn 确保 IStorageService 初始化完成后再初始化自己
    _getIt.registerSingletonAsync<IConfigService>(
      () async {
        final service = ConfigService();
        await service.initialize();
        return service;
      },
      dependsOn: [IStorageService],
    );

    // 4. 注册书籍业务服务（核心大脑：依赖 Storage、Engine 和 Config）
    _getIt.registerSingletonAsync<IBookService>(
      () async {
        final service = BookService();
        await service.initialize();
        return service;
      },
      dependsOn: [IStorageService, IReaderEngine, IConfigService],
    );

    // 【架构师关键指令】：等待所有异步服务按照拓扑顺序完成初始化
    await _getIt.allReady();
  }

  /// 获取服务实例
  static T get<T extends Object>() => _getIt.get<T>();

  /// 检查服务是否已注册
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// 重置服务（系统清理时使用）
  static Future<void> reset() async => await _getIt.reset();
}