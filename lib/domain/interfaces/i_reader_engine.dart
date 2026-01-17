/// 阅读引擎接口（Domain 层核心抽象）
/// 定义书籍渲染和解析的抽象操作，便于后续切换不同的解析引擎
abstract class IReaderEngine {
  /// 初始化引擎
  Future<void> initialize();

  /// 解析书籍文件
  /// [filePath] 文件路径
  /// 返回解析后的书籍内容
  Future<BookContent> parseBook(String filePath);

  /// 渲染书籍内容
  /// [content] 书籍内容
  /// 返回渲染后的 Widget
  Widget renderContent(BookContent content);

  /// 获取书籍元数据
  /// [filePath] 文件路径
  /// 返回书籍元数据
  Future<BookMetadata> getMetadata(String filePath);
}

/// 书籍内容数据模型
class BookContent {
  final String bookName;
  final List<String> pages;
  final Map<String, dynamic>? extraData;

  BookContent({
    required this.bookName,
    required this.pages,
    this.extraData,
  });
}

/// 书籍元数据
class BookMetadata {
  final String title;
  final String? author;
  final int? pageCount;
  final DateTime? publishDate;
  final Map<String, dynamic>? extraData;

  BookMetadata({
    required this.title,
    this.author,
    this.pageCount,
    this.publishDate,
    this.extraData,
  });
}
