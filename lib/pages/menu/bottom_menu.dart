import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_rootstock_wallet/pages/details/account_statements_detail.dart';
import 'package:my_rootstock_wallet/pages/menu/item_menu_botton.dart';


class BottomMenu extends StatefulWidget {
  final bool showMenu;
  const BottomMenu({super.key, required this.showMenu});
  @override
  _BottomMenuState createState() => _BottomMenuState();
}

class _BottomMenuState extends State<BottomMenu> {
  late Tween<double> _tween;

  @override
  void initState() {
    super.initState();
    _tween = Tween<double>(begin: 150.0, end: 0.0);
    //delayAnimation();
  }

  Future<void> delayAnimation() async {
    Future.delayed(const Duration(milliseconds: 0), () {
      (() {
        _tween = Tween<double>(begin: 150.0, end: 0.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
        tween: _tween,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            bottom: !widget.showMenu
                ? 0 + MediaQuery.of(context).padding.bottom
                : 0,
            left: value,
            right: value * -1,
            height: MediaQuery.of(context).size.height * 0.14,
            child: IgnorePointer(
              ignoring: widget.showMenu,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: !widget.showMenu ? 1 : 0,
                child: Container(
                  color: Colors.black,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      ItemMenuBottom(
                        icon: Icons.person_add,
                        text: AppLocalizations.of(context)!.refer,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.phone_android,
                        text: AppLocalizations.of(context)!.recarga,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.chat,
                        text: AppLocalizations.of(context)!.cobrar,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.monetization_on,
                        text: AppLocalizations.of(context)!.emprestimos,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.move_to_inbox,
                        text: AppLocalizations.of(context)!.depositar,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.mobile_screen_share,
                        text: AppLocalizations.of(context)!.transferir,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.format_align_center,
                        text: AppLocalizations.of(context)!.limits,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.chrome_reader_mode,
                        text: AppLocalizations.of(context)!.pagar,
                        widget: const AccountStatementsDetail(),
                      ),
                      ItemMenuBottom(
                        icon: Icons.lock_open,
                        text: AppLocalizations.of(context)!.bloquear,
                        widget: const AccountStatementsDetail(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
