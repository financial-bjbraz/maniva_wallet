import 'package:flutter/material.dart';

import '../../../util/util.dart';

/// Box component on the first page
class CreateWallet extends StatelessWidget {
  const CreateWallet({super.key});

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: purple(),
                        size: 48,
                      ),
                      Text(
                        "Criar uma \n nova wallet ",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: Colors.black,
                            backgroundColor: purple(),
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
