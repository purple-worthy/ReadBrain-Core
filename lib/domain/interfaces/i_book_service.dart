import 'package:dartz/dartz.dart';

/// 书籍服务接口（Domain 层核心抽象）
/// 定义所有书籍相关的业务操作，不依赖具体实现
abstract class IBookService {
  /// 初始化服务
  Future<void> initialize();

  /// 导入书籍文件
  /// [filePath] 文件路径
  /// 返回 Either<Failure, String>，成功返回书籍名称，失败返回错误信息
  Future<Either<String, String>> importBook(String filePath);

  /// 添加书籍到书籍库
  /// [bookName] 书籍名称
  void addBook(String bookName);

  /// 获取所有书籍列表
  List<String> getAllBooks();

  /// 打开书籍（添加到标签页）
  /// [bookName] 书籍名称
  /// 返回 true 表示成功，false 表示失败（页签已达上限）
  bool openBook(String bookName);

  /// 关闭书籍（移除标签页）
  /// [index] 要关闭的标签页索引
  void closeBook(int index);

  /// 切换到指定标签页
  /// [index] 标签页索引
  void switchToBook(int index);

  /// 获取当前打开的书籍列表
  List<String> getOpenBooks();

  /// 获取当前选中的标签页索引
  int getCurrentIndex();

  /// 获取当前选中的书籍名称
  String? getCurrentBook();

  /// 清除所有数据
  void clearAllData();

  /// 获取页签上限
  int getMaxTabs();

  /// 获取书籍封面缓存路径
  /// [bookName] 书籍名称
  /// 返回封面文件路径，如果不存在则返回 null
  Future<String?> getCoverCachePath(String bookName);

  /// 保存书籍封面到缓存
  /// [bookName] 书籍名称
  /// [coverData] 封面数据（字节数组或文件路径）
  /// 返回 true 表示成功，false 表示失败
  Future<bool> saveCoverCache(String bookName, dynamic coverData);

  /// 清除书籍封面缓存
  /// [bookName] 书籍名称，如果为 null 则清除所有封面缓存
  Future<bool> clearCoverCache(String? bookName);

  /// 检查封面缓存是否存在
  /// [bookName] 书籍名称
  /// 返回 true 表示存在，false 表示不存在
  Future<bool> hasCoverCache(String bookName);

  /// 保存书籍最后阅读页码
  /// [bookName] 书籍名称
  /// [pageNumber] 页码（从 0 开始）
  Future<void> saveLastReadPage(String bookName, int pageNumber);

  /// 获取书籍最后阅读页码
  /// [bookName] 书籍名称
  /// 返回页码（从 0 开始），如果没有记录则返回 null
  Future<int?> getLastReadPage(String bookName);

  /// 获取书籍文件路径
  /// [bookName] 书籍名称
  /// 返回文件路径，如果不存在则返回 null
  String? getBookFilePath(String bookName);
}
