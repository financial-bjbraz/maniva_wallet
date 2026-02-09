import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_rootstock_wallet/entities/bitcoin_utxo.dart';
import 'package:my_rootstock_wallet/services/bitcoin_service.dart';

void main() {
  test('sendTransferUsingUtxos builds and sends tx, returns txid', () async {
    // Input from user
    final toAddress = 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546';
    final amount = 0.000004; // BTC

    // Create a Utxo from provided JSON-like data
    final utxoMap = {
      'txid': '7459ad3f651703e854116bbe7eb8b221cd51a6c55a6b0cd29299f9940bde0ed7',
      'vout': 0,
      'amount': 0.00010000,
      'scriptPubKey': '0014a4528547945a44c365d8cb92dbb644ffaaf510f2',
      'address': 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546',
    };

    final utxo = Utxo.fromMap(utxoMap);

    // Fake RPC override to intercept calls
    final calls = <Map<String, dynamic>>[];

    Future<dynamic> fakeRpc(String method, [List<dynamic>? params]) async {
      calls.add({'method': method, 'params': params});

      if (method == 'getrawchangeaddress') {
        return 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546';
      }

      if (method == 'createrawtransaction') {
        // Return a fake raw hex
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

    final txid = await client.sendTransferUsingUtxos(toAddress, amount, [utxo], fee: 0.000001, changeAddress: toAddress);

    expect(txid, equals('faketxid1234567890abcdef'));

    // Check that createrawtransaction, signrawtransactionwithwallet and sendrawtransaction were called
    final methods = calls.map((c) => c['method'] as String).toList();
    expect(methods, containsAll(['createrawtransaction', 'signrawtransactionwithwallet', 'sendrawtransaction']));
  });
}
