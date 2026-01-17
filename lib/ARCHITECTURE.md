# ReadBrain 架构设计文档

## 目录结构

```
lib/
├── domain/                    # Domain 层（核心抽象）
│   └── interfaces/            # 接口定义
│       ├── i_book_service.dart      # 书籍服务接口
│       ├── i_config_service.dart    # 配置服务接口
│       ├── i_reader_engine.dart     # 阅读引擎接口
│       └── i_storage_service.dart   # 存储服务接口
│
├── data/                      # Data 层（具体实现）
│   └── services/             # 服务实现
│       ├── book_service.dart         # 书籍服务实现
│       ├── config_service.dart       # 配置服务实现
│       ├── local_storage_service.dart # 本地存储服务实现
│       └── mock_reader_engine.dart   # 模拟阅读引擎实现
│
├── core/                      # 核心模块
│   └── service_locator.dart  # 服务定位器（依赖注入）
│
└── presentation/              # Presentation 层（UI）
    └── (待重构，当前在 main.dart)
```

## 架构分层说明

### 1. Domain 层（核心抽象）
- **位置**: `lib/domain/interfaces/`
- **职责**: 定义业务逻辑的抽象接口，不依赖任何具体实现
- **特点**: 
  - 纯抽象接口，无具体实现
  - 定义业务契约和规范
  - 便于测试和扩展

### 2. Data 层（具体实现）
- **位置**: `lib/data/services/`
- **职责**: 实现 Domain 层定义的接口
- **特点**:
  - 实现具体的业务逻辑
  - 处理数据持久化
  - 可以轻松替换实现（如切换存储方式、解析引擎等）

### 3. Presentation 层（UI）
- **位置**: `lib/presentation/` (待重构)
- **职责**: 用户界面展示和交互
- **特点**:
  - 通过接口调用服务，不直接依赖具体实现
  - 响应式 UI 更新

## 依赖注入（Service Locator）

使用 `GetIt` 实现依赖注入，所有服务在 `lib/core/service_locator.dart` 中统一注册。

### 服务注册示例

```dart
// 在 service_locator.dart 中注册服务
_getIt.registerSingletonAsync<IBookService>(
  () async {
    final service = BookService();
    await service.initialize();
    return service;
  },
);
```

### 切换实现示例

如果要切换阅读引擎，只需修改 `service_locator.dart` 中的注册代码：

```dart
// 当前使用模拟引擎
_getIt.registerSingletonAsync<IReaderEngine>(
  () async {
    final service = MockReaderEngine();
    await service.initialize();
    return service;
  },
);

// 切换到 PDF 引擎（示例）
// _getIt.registerSingletonAsync<IReaderEngine>(
//   () async {
//     final service = PDFReaderEngine();
//     await service.initialize();
//     return service;
//   },
// );

// 切换到大模型解析引擎（示例）
// _getIt.registerSingletonAsync<IReaderEngine>(
//   () async {
//     final service = LLMReaderEngine();
//     await service.initialize();
//     return service;
//   },
// );
```

## 使用方式

### 在代码中获取服务

```dart
// 获取书籍服务
final bookService = ServiceLocator.get<IBookService>();

// 获取配置服务
final configService = ServiceLocator.get<IConfigService>();

// 获取存储服务
final storageService = ServiceLocator.get<IStorageService>();
```

## 优势

1. **解耦**: 各层之间通过接口通信，降低耦合度
2. **可测试**: 可以轻松注入 Mock 对象进行单元测试
3. **可扩展**: 新增功能只需实现接口，无需修改现有代码
4. **可替换**: 切换实现只需修改服务注册代码
5. **清晰**: 代码结构清晰，职责分明

## 后续扩展

- 添加 `PDFReaderEngine` 实现 PDF 解析
- 添加 `LLMReaderEngine` 实现大模型解析
- 添加 `CloudStorageService` 实现云端存储
- 添加 `CacheService` 实现缓存管理
