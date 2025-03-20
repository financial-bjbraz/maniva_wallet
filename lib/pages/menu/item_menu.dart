import 'package:flutter/material.dart';

class ItemMenu extends StatelessWidget {
  const ItemMenu({super.key, required this.icone, required this.text});

  final IconData icone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      elevation: 0,
    );

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.7,
            color: Colors.white54,
          ),
          top: BorderSide(
            width: 0.7,
            color: Colors.white54,
          ),
        ),
      ),
      child: ElevatedButton(
        style: raisedButtonStyle,
        // color: Color(0x293145),
        // highlightColor: Colors.transparent,
        // elevation: 0,
        // disabledElevation: 0,
        // highlightElevation: 0,
        // hoverElevation: 0,
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icone),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  text,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
