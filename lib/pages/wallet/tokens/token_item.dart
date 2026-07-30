import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hux/hux.dart';
import 'package:logging/logging.dart';

import '../../../util/clipboard_guard.dart';

class TokenItem extends StatelessWidget {
  final String tokenName;
  final String tokenSymbol;
  final String tokenAddress;
  final String tokenBalance;
  final String networkId;

  const TokenItem(
      {super.key,
      required this.tokenName,
      required this.tokenSymbol,
      required this.tokenAddress,
      required this.tokenBalance,
      required this.networkId});

  static final _log = Logger('TokenItem');

  @override
  Widget build(BuildContext context) {
    final tokenIcon = "assets/icons/${networkId}.png";
    final fallbackIcon = "assets/contracts/${tokenSymbol}.png";

    return HuxContextMenu(
      menuItems: [
        HuxContextMenuItem(
            text: 'Copy',
            icon: FeatherIcons.copy,
            onTap: () {
              copyWithTimeout(tokenAddress);
              if (kDebugMode) {
                _log.info('Token address copied to clipboard: $tokenAddress');
              }
            }),
        HuxContextMenuItem(
          text: 'Paste',
          icon: FeatherIcons.clipboard,
          onTap: () {
            if (kDebugMode) {
              _log.info('Paste action triggered');
            }
          },
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
              tokenIcon,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              cacheWidth: 80,
              cacheHeight: 80,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                fallbackIcon,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                cacheWidth: 80,
                cacheHeight: 80,
              ),
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
            if (kDebugMode) {
              _log.info('Card tapped!');
            }
          },
        ),
      ),
    );
  }
}
