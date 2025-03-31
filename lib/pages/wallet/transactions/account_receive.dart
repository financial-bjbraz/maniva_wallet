import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import '../../../entities/simple_user.dart';
import '../../../services/wallet_service.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../util/util.dart';

class Receive extends StatefulWidget {
  final SimpleUser user;
  final WalletDTO walletDto;
  const Receive({super.key, required this.user, required this.walletDto});

  @override
  _Receive createState() {
    return _Receive();
  }
}

class _Receive extends State<Receive> {
  bool processing = false;
  String address = "";
  String completeAddress = "";
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, "");
  final valueController = TextEditingController();
  late String balance = "0";
  late String balanceInUsd = "0";

  _Receive();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    processAddress();
    valueController.dispose();
    super.dispose();
  }

  processAddress() {
    if (address.isEmpty) {
      address = widget.walletDto.getAddress();
      completeAddress = widget.walletDto.getCompleteAddress();
    }
  }

  @override
  Widget build(BuildContext context) {
    processAddress();

    return Container(
      margin: const EdgeInsets.only(top: 5, left: 15, right: 15),
      height: 175,
      color: Colors.black,
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 175,
              decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 10, color: Colors.black, spreadRadius: 5)
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ShowQrCode(completeAddress: completeAddress),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShareButton(
                          completeAddress: completeAddress,
                        ),
                        CopyButton(
                          completeAddress: completeAddress,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ]),
    );
  }
}

class ShareAndCopy extends StatelessWidget {
  final String completeAddress;
  final ethereum = "ethereum:";
  const ShareAndCopy({super.key, required this.completeAddress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            QrImageView(
              data: ethereum + completeAddress,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              embeddedImage: Image.asset("assets/icons/rbtc2.png").image,
              size: 50.0,
            ),
          ],
        ),
      ],
    );
  }
}

class ShowQrCode extends StatelessWidget {
  final String completeAddress;
  final ethereum = "ethereum:";
  const ShowQrCode({super.key, required this.completeAddress});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: ethereum + completeAddress,
      version: QrVersions.auto,
      backgroundColor: Colors.white,
      embeddedImage: Image.asset("assets/icons/rbtc2.png").image,
      size: 175.0,
    );
  }
}

class ShareButton extends StatefulWidget {
  final String completeAddress;
  const ShareButton({super.key, required this.completeAddress});

  @override
  _ShareButton createState() => _ShareButton();
}

class _ShareButton extends State<ShareButton> {
  bool checkingFlight = false;
  bool success = false;

  @override
  Widget build(BuildContext context) {
    return !checkingFlight
        ? ElevatedButton(
            style: blackWhiteButton,
            onPressed: () async {
              final box = context.findRenderObject() as RenderBox?;
              final data = utf8.encode(widget.completeAddress);
              await Share.shareXFiles(
                [
                  XFile.fromData(
                    data,
                    // name: fileName, // Notice, how setting the name here does not work.
                    mimeType: 'text/plain',
                  ),
                ],
                sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                fileNameOverrides: [widget.completeAddress],
              );

              setState(() {
                checkingFlight = true;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                success = true;
              });
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pop(context);
            },
            child: const Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text("Share Your Address", style: smallBlackText),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Icons.share,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          )
        : !success
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.check,
                color: Colors.green,
              );
  }
}

class CopyButton extends StatefulWidget {
  final String completeAddress;
  const CopyButton({super.key, required this.completeAddress});

  @override
  _CopyButton createState() => _CopyButton();
}

class _CopyButton extends State<CopyButton> {
  bool checkingFlight = false;
  bool success = false;

  @override
  Widget build(BuildContext context) {
    return !checkingFlight
        ? ElevatedButton(
            style: blackWhiteButton,
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: widget.completeAddress));

              setState(() {
                checkingFlight = true;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                success = true;
              });
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pop(context);
            },
            child: const Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text("Copy Your Address", style: smallBlackText),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Icons.copy,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          )
        : !success
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.check,
                color: Colors.green,
              );
  }
}
