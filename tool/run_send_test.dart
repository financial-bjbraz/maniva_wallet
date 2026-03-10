import 'dart:async';

import '../lib/entities/bitcoin_utxo.dart';
import '../lib/services/bitcoin_service.dart';

Future<void> main() async {
  const toAddress = 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546';
  const amount = 0.000004;

  final utxoMap = {
    'txid': '7459ad3f651703e854116bbe7eb8b221cd51a6c55a6b0cd29299f9940bde0ed7',
    'vout': 0,
    'amount': 0.00010000,
    'scriptPubKey': '0014a4528547945a44c365d8cb92dbb644ffaaf510f2',
    'address': toAddress,
  };

  final utxo = Utxo.fromMap(utxoMap);

  final calls = <Map<String, dynamic>>[];

  Future<dynamic> fakeRpc(String method, [List<dynamic>? params]) async {
    print('RPC called: $method with params: $params');
    calls.add({'method': method, 'params': params});

    if (method == 'getrawchangeaddress') {
      return toAddress;
    }

    if (method == 'createrawtransaction') {
      return '0200000001deadbeef...';
    }

    if (method == 'signrawtransactionwithwallet') {
      return {'hex': '02000000signed...', 'complete': true};
    }

    if (method == 'sendrawtransaction') {
      return 'faketxid1234567890abcdef';
    }

    if (method == 'estimatesmartfee') {
      return {'feerate': 0.0001};
    }

    throw UnimplementedError('Unexpected RPC method $method');
  }

  final client = BitcoinNodeClient(
    rpcUrl: 'http://127.0.0.1:18332',
    rpcUser: 'user',
    rpcPassword: 'pass',
    rpcCallOverride: fakeRpc,
  );

  try {
    final txid = await client.sendTransferUsingUtxos(toAddress, amount, [utxo],
        fee: 0.000001, changeAddress: toAddress);
    print('txid: $txid');
    final methods = calls.map((c) => c['method'] as String).toList();
    print('methods called: $methods');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
