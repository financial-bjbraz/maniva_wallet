import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:my_rootstock_wallet/contracts/MetaCoin.g.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../../../entities/user_helper.dart';
import '../../../entities/wallet_helper.dart';
import '../../../util/network.dart';
import '../../../util/shimmer_loading.dart';
import '../../../util/util.dart';

class TokensFromNetwork extends StatefulWidget {
  const TokensFromNetwork(
      {super.key,
      required this.wallet,
      required this.user,
      required this.selectedNetwork,
      required this.isLoading,
      required this.currentAddress});

  final WalletEntity wallet;
  final SimpleUser user;
  final Network selectedNetwork;
  final bool isLoading;
  final String currentAddress;

  @override
  _TokensFromNetwork createState() => _TokensFromNetwork();
}

class _TokensFromNetwork extends State<TokensFromNetwork> {
  String accountBalance = "0";
  final String contractAddress = "0xEb58823463DBa4921fACA328750763f1173C9457";
  final String myAddress = "0x02E221A95224F090e492066Bc1B7a35B5Fd94542";
  String tokenSymbol = "";

  getDataFromGeneratedAbi() async {
    try {
      final node = dotenv.env['ROOTSTOCK_NODE'];
      final client = web3.Web3Client(node!, http.Client());
      final credentials = web3.EthPrivateKey.fromHex(widget.wallet.privateKey);
      final address = credentials.address;
      final ownAddress = await credentials.extractAddress();

      final web3.EthereumAddress contractAddr = web3.EthereumAddress.fromHex(contractAddress);
      final web3.EthereumAddress account = web3.EthereumAddress.fromHex(myAddress);
      MetaCoin token = MetaCoin(address: contractAddr, client: client);

      ({web3.EthereumAddress addr}) record = (addr: account);
      var balanceObtained = await token.getBalance(record);
      print("We have ${balanceObtained.toString()} MyTokens :) at address ${ownAddress.hex}");
    } catch (e) {
      print("Error occured on call contract $e");
    }
  }

  loadWalletData() async {
    final node = dotenv.env['ROOTSTOCK_NODE'];
    final client = web3.Web3Client(node!, http.Client());
    final credentials = web3.EthPrivateKey.fromHex(widget.wallet.privateKey);

    final web3.EthereumAddress contractAddr = web3.EthereumAddress.fromHex(contractAddress);
    final web3.EthereumAddress receiver = web3.EthereumAddress.fromHex(myAddress);

    final abiCode = await rootBundle.loadString('assets/contracts/MetaCoin.abi.json');
    final contract =
        web3.DeployedContract(web3.ContractAbi.fromJson(abiCode, 'MetaCoin'), contractAddr);

    final balanceFunction = contract.function('getBalance');

    final balance =
        await client.call(contract: contract, function: balanceFunction, params: [receiver]);
    var balanceObtained = balance.first.toString();

    setState(() {
      accountBalance = balanceObtained;
      print('We have 2 ${accountBalance} MyTokens');
    });
  }

  @override
  Widget build(BuildContext context) {
    loadWalletData();
    getDataFromGeneratedAbi();

    return ShimmerLoading(
      isLoading: widget.isLoading,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.wallet_rounded,
            color: lightBlue(),
          ),
          GestureDetector(
            child: Text.rich(
              TextSpan(
                  text: accountBalance,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                backgroundColor: lightBlue(),
                fontSize: 20,
              ),
            ),
            onTap: () async {},
          )
        ],
      ),
    );
  }
}
