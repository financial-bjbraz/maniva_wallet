// dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../entities/bitcoin_utxo.dart';

class BitcoinNodeClient {
  final Uri rpcUri;
  final String rpcUser;
  final String rpcPassword;

  BitcoinNodeClient({
    required String rpcUrl,
    required this.rpcUser,
    required this.rpcPassword,
  }) : rpcUri = Uri.parse(rpcUrl);

  Future<dynamic> _callRpc(String method, [List<dynamic>? params]) async {
    final body =
        jsonEncode({'jsonrpc': '1.0', 'id': 'dart', 'method': method, 'params': params ?? []});

    final auth = base64Encode(utf8.encode('$rpcUser:$rpcPassword'));
    final resp = await http.post(
      rpcUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $auth',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('RPC HTTP ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (decoded.containsKey('error') && decoded['error'] != null) {
      throw Exception('RPC error: ${decoded['error']}');
    }

    return decoded['result'];
  }

  Future<double> getBalanceForAddress(String address) async {
    try {
      final result = await _callRpc('scantxoutset', [
        'start',
        ['addr($address)']
      ]);

      if (result is Map<String, dynamic>) {
        if (result.containsKey('total_amount')) {
          final total = result['total_amount'];
          if (total is num) return total.toDouble();
          if (total is String) return double.tryParse(total) ?? 0.0;
        }

        if (result.containsKey('unspents')) {
          final unspents = result['unspents'] as List<dynamic>;
          double sum = 0.0;
          for (final u in unspents) {
            if (u is Map<String, dynamic> && u.containsKey('amount')) {
              final amt = u['amount'];
              if (amt is num)
                sum += amt.toDouble();
              else if (amt is String) sum += double.tryParse(amt) ?? 0.0;
            }
          }
          return sum;
        }
      }

      return 0.0;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a list of UTXOs for the given address by calling RPC `listunspent`.
  /// Each item is a `Map<String, dynamic>` with normalized fields (for example
  /// `amount` is converted to `double`).
  Future<List<Map<String, dynamic>>> listUtxos(
    String address, {
    int minConf = 0,
    int maxConf = 9999999,
  }) async {
    final result = await _callRpc('listunspent', [
      minConf,
      maxConf,
      [address]
    ]);

    if (result is! List) return <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> utxos = [];
    for (final item in result) {
      if (item is Map<String, dynamic>) {
        // Normalize amount to double if possible
        final rawAmount = item['amount'];
        final double amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

        final normalized = Map<String, dynamic>.from(item);
        normalized['amount'] = amount;

        utxos.add(normalized);
      }
    }

    return utxos;
  }

  Future<String> sendToAddress(String address, double amount) async {
    final result = await _callRpc('sendtoaddress', [address, amount]);

    if (result is String) {
      return result;
    }

    if (result is Map<String, dynamic> && result.containsKey('txid')) {
      final txid = result['txid'];
      if (txid is String) return txid;
    }

    throw Exception('Failed to send to address: $result');
  }

  /// Uses the provided list of `Utxo` objects as inputs for the created transaction.
  Future<String> sendTransferUsingUtxos(
    String toAddress,
    double amount,
    List<Utxo> utxos, {
    double fee = 0.0001,
    String? changeAddress,
  }) async {
    if (utxos.isEmpty) {
      throw ArgumentError('UTXOs list must not be empty');
    }

    // Build inputs array and sum input amounts using Utxo model
    final List<Map<String, dynamic>> inputs = utxos.map((u) => u.toRpcInput()).toList();
    final double totalIn = utxos.fold(0.0, (double sum, Utxo u) => sum + u.amount);

    // Resolve change address if not provided
    String changeAddr = changeAddress ?? '';
    if (changeAddr.isEmpty) {
      final rawChange = await _callRpc('getrawchangeaddress');
      if (rawChange is String && rawChange.isNotEmpty) {
        changeAddr = rawChange;
      } else {
        throw Exception('Failed to obtain change address from wallet');
      }
    }

    // Compute change and handle dust
    final double dustThreshold = 0.00000546; // ~546 sats
    final double changeAmt = totalIn - amount - fee;
    if (changeAmt < -1e-12) {
      throw Exception('Insufficient funds: inputs ${totalIn} < amount ${amount} + fee ${fee}');
    }

    // Build outputs map
    final Map<String, dynamic> outputs = {toAddress: amount};
    if (changeAmt > dustThreshold) {
      outputs[changeAddr] = double.parse(changeAmt.toStringAsFixed(8));
    } // else treat change as additional fee

    // Create raw transaction
    final raw = await _callRpc('createrawtransaction', [inputs, outputs]);
    String rawHex;
    if (raw is String)
      rawHex = raw;
    else if (raw is Map<String, dynamic> && raw.containsKey('hex'))
      rawHex = raw['hex'] as String;
    else
      throw Exception('createrawtransaction returned unexpected result: $raw');

    // Sign with wallet
    final signed = await _callRpc('signrawtransactionwithwallet', [rawHex]);
    String signedHex;
    if (signed is Map<String, dynamic>) {
      final hex = signed['hex'];
      final complete = signed['complete'];
      if (hex is String && (complete == true || complete == null)) {
        signedHex = hex;
      } else {
        throw Exception('Wallet failed to sign transaction completely: $signed');
      }
    } else if (signed is String) {
      signedHex = signed;
    } else {
      throw Exception('signrawtransactionwithwallet returned unexpected result: $signed');
    }

    // Broadcast
    final sendResult = await _callRpc('sendrawtransaction', [signedHex]);
    if (sendResult is String) return sendResult;
    if (sendResult is Map<String, dynamic> && sendResult.containsKey('txid'))
      return sendResult['txid'] as String;
    return sendResult.toString();
  }
}
