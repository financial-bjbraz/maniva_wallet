// dart
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../entities/bitcoin_utxo.dart';
import '../entities/bitcoin_address_details.dart';

class BitcoinNodeClient {
  final Uri rpcUri;
  final String rpcUser;
  final String rpcPassword;
  /// Optional override to intercept RPC calls (useful for tests).
  final Future<dynamic> Function(String method, [List<dynamic>? params])? rpcCallOverride;
  final log = Logger("WalletServiceImpl");

  BitcoinNodeClient({
    required String rpcUrl,
    required this.rpcUser,
    required this.rpcPassword,
    this.rpcCallOverride,
  }) : rpcUri = Uri.parse(rpcUrl);

  Future<dynamic> _callRpc(String method, [List<dynamic>? params]) async {
    // If a test/test-double provided an override, delegate to it.
    if (rpcCallOverride != null) {
      return await rpcCallOverride!(method, params);
    }
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

      throw StateError('RPC HTTP ${resp.statusCode}: ${resp.body}');
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
  Future<List<Utxo>> listUtxos(
    String address, {
    int minConf = 6,
    int maxConf = 9999999,
  }) async {
    final result = await _callRpc('listunspent', [
      minConf,
      maxConf,
      [address]
    ]);

    if (result is! List) return <Utxo>[];

    final List<Utxo> utxos = [];
    for (final item in result) {
      if (item is Map<String, dynamic>) {
        // Normalize amount to double if possible
        final rawAmount = item['amount'];
        final double amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

        final normalized = Map<String, dynamic>.from(item);
        normalized['amount'] = amount;

        utxos.add(Utxo.fromMap(normalized));
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

  /// Select a set of UTXOs that cover the requested `amount` (in BTC).
  ///
  /// Behavior / contract:
  /// - If `availableUtxos` is provided it will be used. Otherwise `address` must
  ///   be provided and `listUtxos(address)` will be called to fetch UTXOs.
  /// - The method accounts for the estimated fee by calling `estimateFeeByInputs`
  ///   with the currently selected inputs (and `numOutputs`=2 by default).
  /// - Selection is performed greedy by largest-first to minimize number of inputs
  ///   (and therefore fee). If a single UTXO can cover the amount+fee it will be
  ///   chosen (preferring the smallest that fits).
  /// - Returns the list of selected `Utxo` objects. Throws on insufficient funds
  ///   or invalid arguments.
  Future<List<Utxo>> selectUtxosForAmount(
    double amount, {
    List<Utxo>? availableUtxos,
    String? address,
    int numOutputs = 2,
    int confTarget = 6,
    String defaultInputScript = 'p2wpkh',
    double fallbackRateSatsPerVbyte = 50.0,
  }) async {
    if (amount <= 0) throw ArgumentError('amount must be > 0');

    // Acquire UTXOs
    List<Utxo> utxos;
    if (availableUtxos != null) {
      utxos = List<Utxo>.from(availableUtxos);
    } else if (address != null && address.isNotEmpty) {
      final raw = await listUtxos(address);
      // listUtxos now returns List<Utxo>
      utxos = List<Utxo>.from(raw);
    } else {
      throw ArgumentError('Either availableUtxos or address must be provided');
    }

    // Filter spendable if that information exists (prefer spendable==true or null)
    utxos = utxos.where((u) => u.spendable == null || u.spendable == true).toList();

    if (utxos.isEmpty) throw Exception('No available UTXOs');

    // First try: see if a single UTXO can cover amount + fee (using that UTXO's script)
    // We'll compute per-candidate fee and pick the smallest UTXO that satisfies it.
    Utxo? singleCandidate;
    // Sort ascending to prefer smaller single utxo when possible
    final asc = List<Utxo>.from(utxos)..sort((a, b) => a.amount.compareTo(b.amount));
    for (final u in asc) {
      final script = inferInputScriptFromUtxo(u.toMap(), defaultScript: defaultInputScript);
      final fee = await estimateFee(numInputs: 1, numOutputs: numOutputs, confTarget: confTarget, inputScript: script, fallbackRateSatsPerVbyte: fallbackRateSatsPerVbyte);
      if (u.amount >= amount + fee) {
        singleCandidate = u;
        break;
      }
    }
    if (singleCandidate != null) {
      // Return single utxo chosen
      return [singleCandidate];
    }

    // Otherwise, perform greedy selection by largest-first accumulating until
    // sum(inputs) >= amount + fee(inputs)
    final desc = List<Utxo>.from(utxos)..sort((a, b) => b.amount.compareTo(a.amount));
    final List<Utxo> selected = [];
    double selectedSum = 0.0;

    for (final u in desc) {
      selected.add(u);
      selectedSum += u.amount;

      // Estimate fee for the currently selected inputs using estimateFeeByInputs which
      // can accept the utxos list to infer per-input script type.
      final fee = await estimateFeeByInputs(
        numOutputs: numOutputs,
        confTarget: confTarget,
        utxos: selected,
        fallbackRateSatsPerVbyte: fallbackRateSatsPerVbyte,
      );

      if (selectedSum >= amount + fee) {
        return selected;
      }
    }

    // If we reach here, funds are insufficient
    throw Exception('Insufficient funds: available ${utxos.fold(0.0, (p, e) => p + e.amount)} BTC, required ${amount} BTC plus fees');
  }



  /// Calculate fee for a given confirmation target (number of blocks).
  ///
  /// Calls `estimatesmartfee` RPC to obtain a fee rate for `confTarget` (blocks).
  /// Then computes an estimated transaction vsize and fee (in BTC and sats).
  ///
  /// Returns a map with keys:
  /// - `feeBtc` (double): estimated fee in BTC
  /// - `feeSats` (int): estimated fee in sats
  /// - `feeRateSatsPerVbyte` (double): fee rate used (sats/vbyte)
  /// - `txVsize` (int): estimated transaction vsize in vbytes
  Future<Map<String, dynamic>> calculateFeeForBlocks({
    required int confTarget,
    required int numInputs,
    int numOutputs = 2,
    String inputScript = 'p2wpkh',
    double fallbackRateSatsPerVbyte = 50.0,
    List<Utxo>? utxos,
  }) async {
    if (confTarget <= 0) throw ArgumentError('confTarget must be > 0');
    if (numInputs <= 0 && (utxos == null || utxos.isEmpty)) {
      throw ArgumentError('Provide numInputs > 0 or a non-empty utxos list');
    }

    // Determine fee rate (sats/vbyte) using estimatesmartfee RPC, fallback on provided rate
    double feeRateSatsPerVbyte;
    try {
      final result = await _callRpc('estimatesmartfee', [confTarget]);
      if (result is Map && result.containsKey('feerate')) {
        final feerate = result['feerate'];
        final feerateBtcPerKb = feerate is num ? feerate.toDouble() : double.tryParse(feerate?.toString() ?? '') ?? 0.0;
        feeRateSatsPerVbyte = feerateBtcPerKb > 0 ? feerateBtcPerKb * 1e8 / 1000.0 : fallbackRateSatsPerVbyte;
      } else {
        feeRateSatsPerVbyte = fallbackRateSatsPerVbyte;
      }
    } catch (e) {
      feeRateSatsPerVbyte = fallbackRateSatsPerVbyte;
    }

    // Input size inference
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
      totalInputVsize = numInputs * inputVsize;
    }

    final int txVsize = totalInputVsize + numOutputs * outputVsize + txOverhead;
    final int feeSats = (txVsize * feeRateSatsPerVbyte).ceil();

    return {
      'feeBtc': feeSats / 1e8,
      'feeSats': feeSats,
      'feeRateSatsPerVbyte': feeRateSatsPerVbyte,
      'txVsize': txVsize,
    };
  }

  /// Fetch vouts from a Blockbook-compatible REST API for a specific transaction (txid)
  /// and return them as a list of `Utxo` objects. This extracts `scriptPubKey` (hex when
  /// available) and an `address` from each vout when present.
  ///
  /// Parameters:
  /// - txid: transaction id to fetch
  /// - blockbookBaseUrl: optional base URL for blockbook (e.g. https://blockbook.example). If not
  ///   provided the method will throw (to avoid adding dotenv dependency here).
  /// - extraHeaders: optional HTTP headers to include
  Future<List<Utxo>> fetchUtxosFromTransaction(String txid,
      { Map<String, String>? extraHeaders}) async {
    if (txid.isEmpty) throw ArgumentError('txid must not be empty');

    String? blockbookBaseUrl = dotenv.env['BLOCK_BOOK_URL'];
    final base = (blockbookBaseUrl ?? '').trim();
    if (base.isEmpty) {
      throw ArgumentError('blockbookBaseUrl must be provided');
    }

    String normalizedBase = base;
    if (normalizedBase.endsWith('/')) {
      normalizedBase = normalizedBase.substring(0, normalizedBase.length - 1);
    }

    final uri = Uri.parse('$normalizedBase/api/v2/tx-specific/$txid');
    final headers = <String, String>{'Accept': 'application/json', ...?extraHeaders};

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Blockbook HTTP ${resp.statusCode}: ${resp.body}');
    }

    final body = jsonDecode(resp.body);
    Map<String, dynamic>? tx;
    if (body is Map<String, dynamic>) {
      tx = body;
    } else if (body is Map && body.containsKey('data') && body['data'] is Map) {
      tx = body['data'] as Map<String, dynamic>;
    } else {
      return <Utxo>[];
    }

    final vouts = tx['vout'];
    if (vouts is! List) return <Utxo>[];

    final List<Utxo> utxos = [];
    for (var idx = 0; idx < vouts.length; idx++) {
      final v = vouts[idx];
      if (v is! Map<String, dynamic>) continue;

      final Map<String, dynamic> normalized = {};
      normalized['txid'] = txid;

      // vout index
      if (v.containsKey('n')) normalized['vout'] = v['n'];
      else if (v.containsKey('vout')) normalized['vout'] = v['vout'];
      else normalized['vout'] = idx;

      // amount: try 'value' (BTC or sats string), 'valueSat', or 'amount'
      if (v.containsKey('value')) {
        final raw = v['value'];
        if (raw is num) normalized['amount'] = raw.toDouble();
        else if (raw is String) {
          if (RegExp(r'^\d+$').hasMatch(raw)) {
            final sats = int.tryParse(raw) ?? 0;
            normalized['amount'] = sats / 1e8;
          } else {
            normalized['amount'] = double.tryParse(raw) ?? 0.0;
          }
        }
      } else if (v.containsKey('valueSat')) {
        final raw = v['valueSat'];
        if (raw is num) normalized['amount'] = raw.toInt() / 1e8;
        else if (raw is String) normalized['amount'] = (int.tryParse(raw) ?? 0) / 1e8;
      } else if (v.containsKey('amount')) {
        final raw = v['amount'];
        if (raw is num) normalized['amount'] = raw.toDouble();
        else if (raw is String) normalized['amount'] = double.tryParse(raw) ?? 0.0;
      }

      // scriptPubKey
      String? scriptHex;
      if (v.containsKey('scriptPubKey')) {
        final spk = v['scriptPubKey'];
        if (spk is Map<String, dynamic>) {
          if (spk.containsKey('hex')) scriptHex = spk['hex'] as String?;
          else if (spk.containsKey('asm')) scriptHex = spk['asm'] as String?;

          if (spk.containsKey('addresses') && spk['addresses'] is List && (spk['addresses'] as List).isNotEmpty) {
            final addr = (spk['addresses'] as List).firstWhere((_) => true, orElse: () => null);
            if (addr is String) normalized['address'] = addr;
          } else if (spk.containsKey('address') && spk['address'] is String) {
            normalized['address'] = spk['address'];
          }
        } else if (spk is String) {
          scriptHex = spk;
        }
      }

      if (scriptHex == null) {
        if (v.containsKey('hex') && v['hex'] is String) scriptHex = v['hex'] as String?;
        else if (v.containsKey('script') && v['script'] is String) scriptHex = v['script'] as String?;
      }

      if (scriptHex != null) normalized['scriptPubKey'] = scriptHex;

      // addresses directly on vout
      if (!normalized.containsKey('address')) {
        if (v.containsKey('addresses') && v['addresses'] is List && (v['addresses'] as List).isNotEmpty) {
          final addr = (v['addresses'] as List).firstWhere((_) => true, orElse: () => null);
          if (addr is String) normalized['address'] = addr;
        }
      }

      try {
        utxos.add(Utxo.fromMap(normalized));
      } catch (e) {
        log.warning('Skipping malformed vout for tx $txid: $e');
      }
    }

    return utxos;
  }

  /// Fetch address info from a Blockbook-compatible REST API endpoint
  /// `GET {blockbookBaseUrl}/api/v2/address/{address}`.
  ///
  /// Returns a Map with keys:
  /// - `balance` (double, BTC)
  /// - `balanceSats` (int, satoshis)
  /// - `txs` (List<dynamic>) : raw tx objects or txids as returned by Blockbook
  /// - `txids` (List<String>) : extracted txids (if available)
  /// - `raw` (Map<String,dynamic>) : the original parsed response (or its `data` wrapper)
  Future<BitcoinAddressDetails> fetchAddressInfoFromBlockbook(String address,
      { Map<String, String>? extraHeaders}) async {
    if (address.isEmpty) throw ArgumentError('address must not be empty');

    String? blockbookBaseUrl = dotenv.env['BLOCK_BOOK_URL'];
    final base = (blockbookBaseUrl ?? '').trim();
    if (base.isEmpty) {
      throw ArgumentError('blockbookBaseUrl must be provided');
    }

    String normalizedBase = base;
    if (normalizedBase.endsWith('/')) normalizedBase = normalizedBase.substring(0, normalizedBase.length - 1);

    final uri = Uri.parse('$normalizedBase/api/v2/address/$address');
    final headers = <String, String>{'Accept': 'application/json', ...?extraHeaders};

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Blockbook HTTP ${resp.statusCode}: ${resp.body}');
    }

    final body = jsonDecode(resp.body);
    Map<String, dynamic>? data;
    if (body is Map<String, dynamic>) {
      data = body;
    } else if (body is Map && body.containsKey('data') && body['data'] is Map) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      // Unexpected shape
      data = <String, dynamic>{};
    }

    // Normalize balance (prefer 'balance', fallback to totalReceived - totalSent)
    double balanceBtc = 0.0;
    int balanceSats = 0;

    dynamic balRaw = data['balance'] ?? data['balanceSat'] ?? data['balanceSatoshi'];
    if (balRaw == null) {
      // try compute from totals
      final tr = data['totalReceived'] ?? data['total_received'] ?? data['totalReceivedBTC'];
      final ts = data['totalSent'] ?? data['total_sent'] ?? data['totalSentBTC'];
      if (tr != null || ts != null) {
        double recv = 0.0;
        double sent = 0.0;
        if (tr != null) {
          if (tr is num) recv = (tr > 1e6) ? tr.toDouble() / 1e8 : tr.toDouble();
          else if (tr is String) recv = RegExp(r'^\d+$').hasMatch(tr) ? (int.tryParse(tr) ?? 0) / 1e8 : double.tryParse(tr) ?? 0.0;
        }
        if (ts != null) {
          if (ts is num) sent = (ts > 1e6) ? ts.toDouble() / 1e8 : ts.toDouble();
          else if (ts is String) sent = RegExp(r'^\d+$').hasMatch(ts) ? (int.tryParse(ts) ?? 0) / 1e8 : double.tryParse(ts) ?? 0.0;
        }
        balanceBtc = recv - sent;
        balanceSats = (balanceBtc * 1e8).round();
      }
    } else {
      if (balRaw is num) {
        // Heuristic: if value > 1e6 treat as sats
        if (balRaw > 1e6) {
          balanceSats = balRaw.toInt();
          balanceBtc = balanceSats / 1e8;
        } else {
          balanceBtc = balRaw.toDouble();
          balanceSats = (balanceBtc * 1e8).round();
        }
      } else if (balRaw is String) {
        if (RegExp(r'^\d+$').hasMatch(balRaw)) {
          // integer string -> sats
          balanceSats = int.tryParse(balRaw) ?? 0;
          balanceBtc = balanceSats / 1e8;
        } else {
          balanceBtc = double.tryParse(balRaw) ?? 0.0;
          balanceSats = (balanceBtc * 1e8).round();
        }
      }
    }

    // Extract txs / txids
    List<dynamic> txs = [];
    List<String> txids = [];

    if (data.containsKey('txs') && data['txs'] is List) {
      txs = data['txs'] as List<dynamic>;
    } else if (data.containsKey('transactions') && data['transactions'] is List) {
      txs = data['transactions'] as List<dynamic>;
    } else if (data.containsKey('txids') && data['txids'] is List) {
      // sometimes txids returned directly
      final items = data['txids'] as List<dynamic>;
      txids = items.whereType<String>().toList();
    }

    // If txs are present, try to extract txids from their contents
    if (txs.isNotEmpty) {
      for (final t in txs) {
        if (t is String) {
          txids.add(t);
        } else if (t is Map<String, dynamic>) {
          final tid = t['txid'] ?? t['tx_hash'] ?? t['id'];
          if (tid is String) txids.add(tid);
        }
      }
    }

    // Deduplicate txids
    txids = txids.toSet().toList();

    final details = BitcoinAddressDetails(
      balance: balanceBtc,
      balanceSats: balanceSats,
      txs: txs,
      txids: txids,
      raw: data,
    );

    return details;
  }

}
