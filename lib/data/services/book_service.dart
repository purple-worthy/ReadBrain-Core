import 'package:flutter/foundation.dart';
import '../../domain/interfaces/i_book_service.dart';
import '../../domain/interfaces/i_storage_service.dart';
import '../../domain/interfaces/i_config_service.dart';
import '../../core/service_locator.dart';

/// 书籍服务实现（Data 层）
/// 实现 IBookService 接口，负责书籍和标签页的管理
class BookService extends ChangeNotifier implements IBookService {
  // 页签上限常量
  static const int maxTabs = 10;

  // 存储服务（通过依赖注入获取）
  late final IStorageService _storageService;

  // 所有书籍列表（模拟书籍库）
  final List<String> _allBooks = [];

  // 当前打开的书籍列表（标签页）
  final List<String> _openBooks = [];

  // 当前选中的标签页索引
  int _currentIndex = -1;

  // 存储键常量
  static const String _keyOpenBooks = 'open_books';
  static const String _keyCurrentIndex = 'current_index';
  static const String _keyAllBooks = 'all_books';

  BookService() {
    // 从服务定位器获取存储服务
    _storageService = ServiceLocator.get<IStorageService>();
  }

  @override
  Future<void> initialize() async {
    try {
      // 加载所有书籍列表
      final allBooksJson = await _storageService.getStringList(_keyAllBooks);
      if (allBooksJson != null && allBooksJson.isNotEmpty) {
        _allBooks.clear();
        _allBooks.addAll(allBooksJson);
      }

      // 检查是否启用自动恢复
      final configService = ServiceLocator.get<IConfigService>();
      final autoRestore = await configService.getAutoRestore();

      if (autoRestore) {
        await _restoreState();
      }
    } catch (e) {
      debugPrint('BookService 初始化失败: $e');
    }
  }

  /// 恢复应用状态（从存储服务加载）
  Future<void> _restoreState() async {
    try {
      // 加载打开的书籍列表
      final openBooksJson = await _storageService.getStringList(_keyOpenBooks);
      if (openBooksJson != null && openBooksJson.isNotEmpty) {
        _openBooks.clear();
        _openBooks.addAll(openBooksJson);

        // 加载当前选中的索引
        final savedIndex = await _storageService.getInt(_keyCurrentIndex);
        _currentIndex = savedIndex ?? 0;

        // 确保索引有效
        if (_currentIndex < 0 || _currentIndex >= _openBooks.length) {
          _currentIndex = _openBooks.isNotEmpty ? 0 : -1;
        }

        // 将打开的书籍也添加到书籍库（如果不存在）
        for (final book in _openBooks) {
          if (!_allBooks.contains(book)) {
            _allBooks.add(book);
          }
        }

        // 保存更新后的书籍库
        await _saveAllBooks();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('恢复状态失败: $e');
    }
  }

  /// 保存应用状态（到存储服务）
  Future<void> _saveState() async {
    try {
      // 保存打开的书籍列表
      await _storageService.saveStringList(_keyOpenBooks, _openBooks);

      // 保存当前选中的索引
      await _storageService.saveInt(_keyCurrentIndex, _currentIndex);
    } catch (e) {
      debugPrint('保存状态失败: $e');
    }
  }

  /// 保存所有书籍列表
  Future<void> _saveAllBooks() async {
    try {
      await _storageService.saveStringList(_keyAllBooks, _allBooks);
    } catch (e) {
      debugPrint('保存书籍库失败: $e');
    }
  }

  @override
  void addBook(String bookName) {
    if (!_allBooks.contains(bookName)) {
      _allBooks.add(bookName);
      _saveAllBooks();
      notifyListeners();
    }
  }

  @override
  List<String> getAllBooks() {
    return List.unmodifiable(_allBooks);
  }

  @override
  bool openBook(String bookName) {
    // 检查页签上限
    if (_openBooks.length >= maxTabs) {
      // 返回 false 表示失败，由 UI 层处理提示
      return false;
    }

    // 如果书籍不在书籍库中，先添加到书籍库
    if (!_allBooks.contains(bookName)) {
      _allBooks.add(bookName);
      _saveAllBooks();
    }

    // 如果书籍已经打开，则切换到该标签页
    final existingIndex = _openBooks.indexOf(bookName);
    if (existingIndex != -1) {
      _currentIndex = existingIndex;
      notifyListeners();
      _saveState();
      return true;
    }

    // 添加新标签页
    _openBooks.add(bookName);
    _currentIndex = _openBooks.length - 1;

    notifyListeners();
    _saveState();
    return true;
  }

  @override
  void closeBook(int index) {
    if (index < 0 || index >= _openBooks.length) return;

    _openBooks.removeAt(index);

    // 调整当前索引
    if (_openBooks.isEmpty) {
      _currentIndex = -1;
    } else if (_currentIndex >= _openBooks.length) {
      _currentIndex = _openBooks.length - 1;
    } else if (_currentIndex > index) {
      _currentIndex--;
    }

    notifyListeners();
    _saveState();
  }

  @override
  void switchToBook(int index) {
    if (index >= 0 && index < _openBooks.length) {
      _currentIndex = index;
      notifyListeners();
      _saveState();
    }
  }

  @override
  List<String> getOpenBooks() {
    return List.unmodifiable(_openBooks);
  }

  @override
  int getCurrentIndex() {
    return _currentIndex;
  }

  @override
  String? getCurrentBook() {
    if (_currentIndex >= 0 && _currentIndex < _openBooks.length) {
      return _openBooks[_currentIndex];
    }
    return null;
  }

  @override
  void clearAllData() {
    _allBooks.clear();
    _openBooks.clear();
    _currentIndex = -1;
    notifyListeners();
    _saveState();
    _saveAllBooks();
  }

  @override
  int getMaxTabs() {
    return maxTabs;
  }
}
