import 'package:flutter/material.dart';

import '../../util/app_theme.dart';
import '../../util/util.dart';

class MyAppBar extends StatefulWidget {
  final bool showMenu;
  final VoidCallback onTap;
  final String userName;

  const MyAppBar({super.key, required this.showMenu, required this.onTap, required this.userName});

  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = lightBlue() ?? rootstockCream;
    return Column(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).padding.top,
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hovered ? accent : rootstockCream.withValues(alpha: 0.3),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: rootstockBlack,
              ),
              height: MediaQuery.of(context).size.height * .15,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset('assets/images/maniva_logo_white.png', height: 50),
                    ],
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    scale: _hovered ? 1.25 : 1.0,
                    child: Icon(
                      widget.showMenu ? Icons.expand_less : Icons.expand_more,
                      color: _hovered ? accent : rootstockCream,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
