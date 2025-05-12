// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Rewards extends StatefulWidget {
  const Rewards({super.key});

  @override
  _RewardsState createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> with AutomaticKeepAliveClientMixin {
  var randon = Random();

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(88, 36),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    elevation: 0,
  );

  _RewardsState();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: <Widget>[
          SvgPicture.asset(
            "assets/icons/gift-outline.svg",
            color: Colors.grey,
            semanticsLabel: "gift",
          ),
          Column(
            children: [
              const Text(
                "Nubank Rewards",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 26),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "Acumule pontos que nunca expiram e troque por passagens aéreas ou serviços realmente úteis.",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(width: 0.7, color: const Color(0x00293145)),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14)),
              onPressed: () {
                setState(() {});
              },
              child: const Text("ATIVE O SEU REWARDS 0 "),
            ),

            // elevation: 0,
            // disabledElevation: 0,
            // highlightElevation: 0,
            // focusElevation: 0,
            // hoverElevation: 0,
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.circular(3),
            // ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
