import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/interfaces/i_book_service.dart';
import '../../domain/interfaces/i_storage_service.dart';
import '../../domain/interfaces/i_config_service.dart';
import '../../domain/interfaces/i_reader_engine.dart';
import '../../core/service_locator.dart';

/// 书籍服务实现（Data 层）
/// 实现 IBookService 接口，负责书籍和标签页的管理
class BookService extends ChangeNotifier implements IBookService {
  // 页签上限常量
  static const int maxTabs = 10;

  // 存储服务（通过依赖注入获取）
  late final IStorageService _storageService;
  
  // 阅读引擎（通过依赖注入获取）
  late final IReaderEngine _readerEngine;

  // 所有书籍列表（模拟书籍库）
  final List<String> _allBooks = [];

  // 当前打开的书籍列表（标签页）
  final List<String> _openBooks = [];

  // 当前选中的标签页索引
  int _currentIndex = -1;
  
  // 书籍文件路径映射（书籍名称 -> 文件路径）
  final Map<String, String> _bookPaths = {};

  // 存储键常量
  static const String _keyOpenBooks = 'open_books';
  static const String _keyCurrentIndex = 'current_index';
  static const String _keyAllBooks = 'all_books';
  static const String _keyBookPaths = 'book_paths';

  BookService() {
    // 从服务定位器获取存储服务和阅读引擎
    _storageService = ServiceLocator.get<IStorageService>();
    _readerEngine = ServiceLocator.get<IReaderEngine>();
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
      
      // 加载书籍路径映射
      final bookPathsJson = await _storageService.getStringList(_keyBookPaths);
      if (bookPathsJson != null && bookPathsJson.isNotEmpty) {
        // 格式：bookName|filePath
        for (final entry in bookPathsJson) {
          final parts = entry.split('|');
          if (parts.length == 2) {
            _bookPaths[parts[0]] = parts[1];
          }
        }
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

  @override
  Future<Either<String, String>> importBook(String filePath) async {
    try {
      // 检查文件是否存在
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        return Left('文件不存在: $filePath');
      }

      // 获取文件名作为书籍名称
      final bookName = sourceFile.path.split(Platform.pathSeparator).last;
      
      // 检查书籍是否已存在
      if (_allBooks.contains(bookName)) {
        // 如果已存在，检查文件路径是否相同
        final existingPath = _bookPaths[bookName];
        if (existingPath == filePath || existingPath != null) {
          return Right(bookName);
        }
      }

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      
      // 确保书籍目录存在
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // 拷贝文件到应用目录
      final targetPath = '${booksDir.path}/$bookName';
      final targetFile = File(targetPath);
      
      // 如果目标文件已存在，先删除
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // 拷贝文件
      await sourceFile.copy(targetPath);

      // 尝试获取封面
      try {
        final coverData = await _readerEngine.getCover(targetPath);
        if (coverData != null) {
          await saveCoverCache(bookName, coverData);
        }
      } catch (e) {
        debugPrint('获取封面失败: $e');
      }

      // 添加到书籍库
      addBook(bookName);
      
      // 保存文件路径映射（保存应用内的路径）
      _bookPaths[bookName] = targetPath;
      await _saveBookPaths();

      return Right(bookName);
    } catch (e) {
      debugPrint('导入书籍失败: $e');
      return Left('导入书籍失败: $e');
    }
  }

  /// 保存书籍路径映射
  Future<void> _saveBookPaths() async {
    try {
      final pathsList = _bookPaths.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();
      await _storageService.saveStringList(_keyBookPaths, pathsList);
    } catch (e) {
      debugPrint('保存书籍路径失败: $e');
    }
  }

  /// 获取书籍文件路径
  String? _getBookFilePath(String bookName) {
    return _bookPaths[bookName];
  }

  @override
  Future<String?> getCoverCachePath(String bookName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${directory.path}/covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }
      return '${coverDir.path}/${_sanitizeFileName(bookName)}.jpg';
    } catch (e) {
      debugPrint('获取封面缓存路径失败: $e');
      return null;
    }
  }

  @override
  Future<bool> saveCoverCache(String bookName, dynamic coverData) async {
    try {
      final cachePath = await getCoverCachePath(bookName);
      if (cachePath == null) return false;

      if (coverData is Uint8List) {
        // 如果是字节数组，直接写入
        final file = File(cachePath);
        await file.writeAsBytes(coverData);
      } else if (coverData is String) {
        // 如果是文件路径，复制文件
        final sourceFile = File(coverData);
        if (await sourceFile.exists()) {
          final targetFile = File(cachePath);
          await sourceFile.copy(targetFile.path);
        } else {
          return false;
        }
      } else {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('保存封面缓存失败: $e');
      return false;
    }
  }

  @override
  Future<bool> clearCoverCache(String? bookName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${directory.path}/covers');
      
      if (!await coverDir.exists()) {
        return true; // 目录不存在，视为清除成功
      }

      if (bookName == null) {
        // 清除所有封面缓存
        await coverDir.delete(recursive: true);
        await coverDir.create(recursive: true);
      } else {
        // 清除指定书籍的封面缓存
        final cachePath = await getCoverCachePath(bookName);
        if (cachePath != null) {
          final file = File(cachePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('清除封面缓存失败: $e');
      return false;
    }
  }

  @override
  Future<bool> hasCoverCache(String bookName) async {
    try {
      final cachePath = await getCoverCachePath(bookName);
      if (cachePath == null) return false;
      
      final file = File(cachePath);
      return await file.exists();
    } catch (e) {
      debugPrint('检查封面缓存失败: $e');
      return false;
    }
  }

  /// 清理文件名，移除非法字符
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
