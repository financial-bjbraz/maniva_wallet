import 'package:flutter/material.dart';

import '../../util/app_theme.dart';
import '../../util/util.dart';

class ItemMenu extends StatefulWidget {
  const ItemMenu({super.key, required this.icone, required this.text, this.onTap});

  final IconData icone;
  final String text;
  final VoidCallback? onTap;

  @override
  State<ItemMenu> createState() => _ItemMenuState();
}

class _ItemMenuState extends State<ItemMenu> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = lightBlue() ?? rootstockCream;
    final currentColor = _hovered ? accent : rootstockCream;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        transform: Matrix4.translationValues(_hovered ? 6 : 0, 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _hovered ? accent.withValues(alpha: 0.10) : Colors.transparent,
          border: Border(
            bottom: BorderSide(width: 0.7, color: rootstockCream.withValues(alpha: 0.24)),
            top: BorderSide(width: 0.7, color: rootstockCream.withValues(alpha: 0.24)),
          ),
        ),
        child: ElevatedButton(
          style: raisedButtonStyleFlat.copyWith(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.08)),
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
          onPressed: widget.onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(widget.icone, color: currentColor),
                  const SizedBox(width: 10),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      color: currentColor,
                      fontWeight: _hovered ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(widget.text),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, size: 16, color: currentColor),
            ],
          ),
        ),
      ),
    );
  }
}
