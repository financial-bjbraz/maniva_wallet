import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hux/hux.dart';

class TokenItem extends StatelessWidget {
  final String tokenName;
  final String tokenSymbol;
  final String tokenAddress;
  final String tokenBalance;

  const TokenItem(
      {super.key,
      required this.tokenName,
      required this.tokenSymbol,
      required this.tokenAddress,
      required this.tokenBalance});

  @override
  Widget build(BuildContext context) {
    return HuxContextMenu(
      menuItems: [
        HuxContextMenuItem(
          text: 'Copy',
          icon: FeatherIcons.copy,
          onTap: () => print('Copy action'),
        ),
        HuxContextMenuItem(
          text: 'Paste',
          icon: FeatherIcons.clipboard,
          onTap: () => print('Paste action'),
        ),
      ],
      child: Card(
        elevation: 5, // Adds a shadow to the card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        margin: const EdgeInsets.all(16), // Margin around the card
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
            child: Image.asset(
              "assets/images/rif.png",
              fit: BoxFit.cover,
            ),
          ), // Icon on the left
          title: Text(
            tokenName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ), // Main text
          subtitle: Text(
            tokenBalance,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ), // Secondary text
          onTap: () {
            // Handle tap event on the card
            print('Card tapped!');
          },
        ),
      ),
    );
  }
}
