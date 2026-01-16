// dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../entities/bitcoin_utxo.dart';
import '../entities/wallet_dto.dart';
import '../entities/wallet_helper.dart';
import 'package:logging/logging.dart';

class BitcoinNodeClient {
  final Uri rpcUri;
  final String rpcUser;
  final String rpcPassword;
  final log = Logger("WalletServiceImpl");

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

  /// Infer script type from a Bitcoin address prefix.
  /// Returns: 'p2tr', 'p2wpkh', 'p2sh-p2wpkh', 'p2pkh', 'other'
  String inferInputScriptFromAddress(String? address, {String defaultScript = 'p2wpkh'}) {
    if (address == null || address.isEmpty) return defaultScript;
    final a = address.toLowerCase();

    // Bech32 v1 (taproot) - e.g. bc1p..., tb1p...
    if (a.startsWith('bc1p') || a.startsWith('tb1p')) return 'p2tr';

    // Bech32 v0 (native segwit) - e.g. bc1q..., tb1q...
    if (a.startsWith('bc1q') || a.startsWith('tb1q')) return 'p2wpkh';

    // P2SH (mainnet: 3, testnet: 2) - often P2SH-P2WPKH when wrapped segwit
    if (a.startsWith('3') || a.startsWith('2')) return 'p2sh-p2wpkh';

    // Legacy P2PKH (mainnet: 1)
    if (a.startsWith('1')) return 'p2pkh';

    return defaultScript;
  }

/*
Example usage:
final script = inferInputScriptFromUtxo(utxoMap);
final perInputVsize = perInputVsizeMap[script] ?? perInputVsizeMap['p2wpkh'];
*/

  /// Infer script type from a UTXO map (as returned by `listunspent`), falling back to address.
  String inferInputScriptFromUtxo(Map<String, dynamic> utxo, {String defaultScript = 'p2wpkh'}) {
    try {
      // Prefer scriptPubKey.type when available (Bitcoin Core formats)
      final spk = utxo['scriptPubKey'];
      if (spk is Map<String, dynamic>) {
        final type = (spk['type'] as String?)?.toLowerCase();
        if (type != null) {
          if (type.contains('witness_v1') || type.contains('taproot')) return 'p2tr';
          if (type.contains('witness_v0') && type.contains('keyhash')) return 'p2wpkh';
          if (type.contains('scripthash')) return 'p2sh-p2wpkh';
          if (type.contains('pubkeyhash')) return 'p2pkh';
          // other witness/script types could be handled here
        }

        final addr = spk['address'] as String? ??
            (spk['addresses'] is List
                ? (spk['addresses'] as List).firstWhere((_) => true, orElse: () => null) as String?
                : null);
        if (addr != null && addr.isNotEmpty) {
          return inferInputScriptFromAddress(addr, defaultScript: defaultScript);
        }
      }

      // Fallback: check top-level address field
      final topAddr = utxo['address'] as String?;
      if (topAddr != null && topAddr.isNotEmpty)
        return inferInputScriptFromAddress(topAddr, defaultScript: defaultScript);
    } catch (_) {
      // ignore and fallback
    }

    return defaultScript;
  }

  Map<String, String> kScriptTypeDescriptions = {
    // Legacy (non-segwit) pays-to-pubkey-hash: larger scriptSig, larger vsize.
    'p2pkh': 'Legacy (Pay-to-PubKey-Hash). Older, non-SegWit format. Uses a scriptSig with '
        'signature + pubkey -> larger vsize (~148 vbytes per input).',

    // Native SegWit v0 (P2WPKH) reduces weight by moving signature data to witness.
    'p2wpkh': 'Native SegWit v0 (Pay-to-Witness-PubKey-Hash). Witness data moves signatures '
        'out of the traditional scriptSig, yielding much smaller vsize (~68 vbytes per input).',

    // SegWit-compatible: P2SH wrapping of a SegWit redeem script.
    'p2sh-p2wpkh': 'SegWit-compatible (P2SH-P2WPKH). A P2SH wrapper around a P2WPKH redeem script. '
        'Slightly larger than native SegWit due to the P2SH wrapper (~91 vbytes per input).',

    // Taproot (P2TR) is compact and more efficient than earlier types.
    'p2tr':
        'Taproot (P2TR). Newer script type with compact witness and fewer bytes in common cases '
            '(very efficient; e.g. ~57 vbytes per input).',

    // Generic placeholder for other or uncommon input types.
    'other': 'Other script types (e.g., multisig, bare scripts). Size varies widely; use a '
        'conservative estimate or compute exact vsize from script details.'
  };

  Future<double> estimateFeeByInputs({
    int numOutputs = 2,
    int confTarget = 6,
    String inputScript = 'p2wpkh', // 'p2pkh', 'p2wpkh', 'p2sh-p2wpkh', 'p2tr'
    double fallbackRateSatsPerVbyte = 50.0,
    List<Utxo>? utxos,
  }) async {
    // Determine inputs and compute total input vsize (infer from utxos if provided)
    int inputs = (utxos != null && utxos.isNotEmpty) ? utxos.length : 1;

    try {
      final result = await _callRpc('estimatesmartfee', [confTarget]);

      double feeRateSatsPerVbyte;
      if (result is Map && result.containsKey('feerate')) {
        final feerate = result['feerate'];
        final feerateBtcPerKb =
            feerate is num ? feerate.toDouble() : double.tryParse(feerate?.toString() ?? '') ?? 0.0;
        feeRateSatsPerVbyte =
            feerateBtcPerKb > 0 ? feerateBtcPerKb * 1e8 / 1000.0 : fallbackRateSatsPerVbyte;
      } else {
        feeRateSatsPerVbyte = fallbackRateSatsPerVbyte;
      }

      final Map<String, int> perInputVsize = {
        'p2pkh': 148,
        'p2wpkh': 68,
        'p2sh-p2wpkh': 91,
        'p2tr': 57,
      };

      const int outputVsize = 34;
      const int txOverhead = 10;

      int totalInputVsize = 0;

      if (utxos != null && utxos.isNotEmpty) {
        for (final u in utxos) {
          String chosenScript = inputScript;
          try {
            final addr = (u as dynamic).address as String?;
            if (addr != null) {
              final a = addr.toLowerCase();
              if (a.startsWith('bc1p') || a.startsWith('tb1p')) {
                chosenScript = 'p2tr';
              } else if (a.startsWith('bc1q') || a.startsWith('tb1q')) {
                chosenScript = 'p2wpkh';
              } else if (a.startsWith('3') || a.startsWith('2')) {
                chosenScript = 'p2sh-p2wpkh';
              } else if (a.startsWith('1')) {
                chosenScript = 'p2pkh';
              }
            }
          } catch (_) {
            // fallback to provided inputScript
          }
          totalInputVsize += perInputVsize[chosenScript] ?? perInputVsize[inputScript]!;
        }
      } else {
        final int inputVsize = perInputVsize[inputScript] ?? perInputVsize['p2wpkh']!;
        totalInputVsize = inputs * inputVsize;
      }

      final int txVsize = totalInputVsize + numOutputs * outputVsize + txOverhead;
      final int feeSats = (txVsize * feeRateSatsPerVbyte).ceil();
      return feeSats / 1e8;
    } catch (e) {
      // On error, compute fee using fallback rate and same input vsize inference
      final Map<String, int> perInputVsize = {
        'p2pkh': 148,
        'p2wpkh': 68,
        'p2sh-p2wpkh': 91,
        'p2tr': 57,
      };
      const int outputVsize = 34;
      const int txOverhead = 10;

      int totalInputVsize = 0;
      if (utxos != null && utxos.isNotEmpty) {
        for (final u in utxos) {
          String chosenScript = inputScript;
          try {
            final addr = (u as dynamic).address as String?;
            if (addr != null) {
              final a = addr.toLowerCase();
              if (a.startsWith('bc1p') || a.startsWith('tb1p')) {
                chosenScript = 'p2tr';
              } else if (a.startsWith('bc1q') || a.startsWith('tb1q')) {
                chosenScript = 'p2wpkh';
              } else if (a.startsWith('3') || a.startsWith('2')) {
                chosenScript = 'p2sh-p2wpkh';
              } else if (a.startsWith('1')) {
                chosenScript = 'p2pkh';
              }
            }
          } catch (_) {}
          totalInputVsize += perInputVsize[chosenScript] ?? perInputVsize[inputScript]!;
        }
      } else {
        final int inputVsize = perInputVsize[inputScript] ?? perInputVsize['p2wpkh']!;
        totalInputVsize = inputs * inputVsize;
      }

      final int txVsize = totalInputVsize + numOutputs * outputVsize + txOverhead;
      final int feeSats = (txVsize * fallbackRateSatsPerVbyte).ceil();
      return feeSats / 1e8;
    }
  }

  Future<double> estimateFee({
    required int numInputs,
    int numOutputs = 2,
    int confTarget = 6,
    String inputScript = 'p2wpkh', // 'p2pkh', 'p2wpkh', 'p2sh-p2wpkh', 'p2tr'
    double fallbackRateSatsPerVbyte = 50.0,
  }) async {
    if (numInputs <= 0) {
      throw ArgumentError('numInputs must be > 0');
    }

    try {
      // Call Bitcoin Core RPC estimatesmartfee
      final result = await _callRpc('estimatesmartfee', [confTarget]);

      // estimatesmartfee returns a map with 'feerate' in BTC/kB when available
      double feeRateSatsPerVbyte;
      if (result is Map && result.containsKey('feerate')) {
        final feerate = result['feerate'];
        final feerateBtcPerKb =
            feerate is num ? feerate.toDouble() : double.tryParse(feerate?.toString() ?? '') ?? 0.0;
        if (feerateBtcPerKb > 0) {
          feeRateSatsPerVbyte = feerateBtcPerKb * 1e8 / 1000.0;
        } else {
          feeRateSatsPerVbyte = fallbackRateSatsPerVbyte;
        }
      } else {
        feeRateSatsPerVbyte = fallbackRateSatsPerVbyte;
      }

      // Typical vsize per input by script type (approximate)
      final Map<String, int> perInputVsize = {
        'p2pkh': 148,
        'p2wpkh': 68,
        'p2sh-p2wpkh': 91,
        'p2tr': 57,
      };
      final int inputVsize = perInputVsize[inputScript] ?? perInputVsize['p2wpkh']!;

      // Typical vsize per output (P2PKH ~34, P2WPKH ~31). Use 34 as conservative value.
      const int outputVsize = 34;

      // Transaction overhead (version, locktime, segwit flag, varints) ~10 vbytes
      const int txOverhead = 10;

      final int txVsize = numInputs * inputVsize + numOutputs * outputVsize + txOverhead;

      final int feeSats = (txVsize * feeRateSatsPerVbyte).ceil();
      final double feeBtc = feeSats / 1e8;

      return feeBtc;
    } catch (e) {
      // On error, compute fee using fallback rate
      final Map<String, int> perInputVsize = {
        'p2pkh': 148,
        'p2wpkh': 68,
        'p2sh-p2wpkh': 91,
        'p2tr': 57,
      };
      final int inputVsize = perInputVsize[inputScript] ?? perInputVsize['p2wpkh']!;
      const int outputVsize = 34;
      const int txOverhead = 10;
      final int txVsize = numInputs * inputVsize + numOutputs * outputVsize + txOverhead;
      final int feeSats = (txVsize * fallbackRateSatsPerVbyte).ceil();
      return feeSats / 1e8;
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
