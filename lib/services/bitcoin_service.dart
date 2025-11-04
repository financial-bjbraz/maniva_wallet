// dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class BitcoinNodeClient {
  final Uri rpcUri;
  final String rpcUser;
  final String rpcPassword;

  BitcoinNodeClient({
    required String rpcUrl,
    required this.rpcUser,
    required this.rpcPassword,
  }) : rpcUri = Uri.parse(rpcUrl);

  Future<Map<String, dynamic>> _callRpc(String method, [List<dynamic>? params]) async {
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
    return decoded['result'] as Map<String, dynamic>;
  }

  /// Returns the balance in BTC for the given address.
  /// Uses `scantxoutset` with `addr(<address>)` and reads `total_amount` or sums `unspents`.
  Future<double> getBalanceForAddress(String address) async {
    try {
      final result = await _callRpc('scantxoutset', [
        'start',
        ['addr($address)']
      ]);

      if (result.containsKey('total_amount')) {
        // Bitcoin Core returns amount in BTC (float). Convert to double.
        final total = result['total_amount'];
        if (total is num) return total.toDouble();
        if (total is String) return double.tryParse(total) ?? 0.0;
      }

      // Fallback: sum unspents array if present
      if (result.containsKey('unspents')) {
        final unspents = result['unspents'] as List<dynamic>;
        double sum = 0.0;
        for (final u in unspents) {
          final amt = u['amount'];
          if (amt is num)
            sum += amt.toDouble();
          else if (amt is String) sum += double.tryParse(amt) ?? 0.0;
        }
        return sum;
      }

      return 0.0;
    } catch (e) {
      // Propagate or return 0.0 depending on desired behavior
      rethrow;
    }
  }
}

/*
Example usage:

final client = BitcoinNodeClient(
  rpcUrl: 'http://127.0.0.1:8332',
  rpcUser: 'rpcuser',
  rpcPassword: 'rpcpass',
);

final balance = await client.getBalanceForAddress('mynetworkaddress...');
print('Balance: $balance BTC');
*/
