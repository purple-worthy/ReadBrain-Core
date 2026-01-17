import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 书籍右键菜单
class BookContextMenu extends StatelessWidget {
  final String bookName;
  final VoidCallback? onOpen;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  const BookContextMenu({
    super.key,
    required this.bookName,
    this.onOpen,
    this.onRename,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'open':
            onOpen?.call();
            break;
          case 'rename':
            onRename?.call();
            break;
          case 'remove':
            onRemove?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.bookOpen, size: 16),
              const SizedBox(width: 12),
              const Text('打开'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.pen, size: 16),
              const SizedBox(width: 12),
              const Text('重命名'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
              const SizedBox(width: 12),
              const Text('从库中移除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
