/// 书籍服务接口（Domain 层核心抽象）
/// 定义所有书籍相关的业务操作，不依赖具体实现
abstract class IBookService {
  /// 初始化服务
  Future<void> initialize();

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
}
