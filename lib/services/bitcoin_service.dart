// dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartsv/dartsv.dart' as dartsv;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../entities/bitcoin_utxo.dart';

class BitcoinNodeClient {
  final Uri rpcUri;
  final String rpcUser;
  final String rpcPassword;

  /// Optional override to intercept RPC calls (useful for tests).
  final Future<dynamic> Function(String method, [List<dynamic>? params])? rpcCallOverride;
  final log = Logger("BitcoinNodeClient");

  BitcoinNodeClient({
    required String rpcUrl,
    this.rpcUser = '',
    this.rpcPassword = '',
    this.rpcCallOverride,
  }) : rpcUri = Uri.parse(rpcUrl);

  Future<dynamic> _callRpc(String method, [List<dynamic>? params]) async {
    // If a test/test-double provided an override, delegate to it.
    if (rpcCallOverride != null) {
      return rpcCallOverride!(method, params);
    }
    final body =
        jsonEncode({'jsonrpc': '1.0', 'id': 'dart', 'method': method, 'params': params ?? []});

    final headers = {'Content-Type': 'application/json'};
    if (rpcUser.isNotEmpty || rpcPassword.isNotEmpty) {
      headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('$rpcUser:$rpcPassword'))}';
    }
    final resp = await http.post(rpcUri, headers: headers, body: body);

    if (resp.statusCode != 200) {
      throw StateError('RPC HTTP ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (decoded.containsKey('error') && decoded['error'] != null) {
      throw Exception('RPC error: ${decoded['error']}');
    }

    return decoded['result'];
  }

  /// Returns the confirmed BTC balance for [address] by scanning the UTXO set
  /// via RPC `scantxoutset`. Only available on self-hosted nodes; public RPC
  /// providers reject this method — prefer [fetchBalanceFromEsplora] instead.
  Future<double> getBalanceForAddress(String address) async {
    try {
      final result = await _callRpc('scantxoutset', [
        'start',
        ['addr($address)']
      ]);

      if (result is Map<String, dynamic>) {
        if (result.containsKey('total_amount')) {
          final total = result['total_amount'];
          if (total is num) {
            return total.toDouble();
          }
          if (total is String) {
            return double.tryParse(total) ?? 0.0;
          }
        }

        if (result.containsKey('unspents')) {
          final unspents = result['unspents'] as List<dynamic>;
          double sum = 0.0;
          for (final u in unspents) {
            if (u is Map<String, dynamic> && u.containsKey('amount')) {
              final amt = u['amount'];
              if (amt is num) {
                sum += amt.toDouble();
              } else if (amt is String) {
                sum += double.tryParse(amt) ?? 0.0;
              }
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
    if (address == null || address.isEmpty) {
      return defaultScript;
    }
    final a = address.toLowerCase();

    // Bech32 v1 (taproot) - e.g. bc1p..., tb1p...
    if (a.startsWith('bc1p') || a.startsWith('tb1p')) {
      return 'p2tr';
    }

    // Bech32 v0 (native segwit) - e.g. bc1q..., tb1q...
    if (a.startsWith('bc1q') || a.startsWith('tb1q')) {
      return 'p2wpkh';
    }

    // P2SH (mainnet: 3, testnet: 2) - often P2SH-P2WPKH when wrapped segwit
    if (a.startsWith('3') || a.startsWith('2')) {
      return 'p2sh-p2wpkh';
    }

    // Legacy P2PKH (mainnet: 1, testnet: m or n)
    if (a.startsWith('1') || a.startsWith('m') || a.startsWith('n')) {
      return 'p2pkh';
    }

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
          if (type.contains('witness_v1') || type.contains('taproot')) {
            return 'p2tr';
          }
          if (type.contains('witness_v0') && type.contains('keyhash')) {
            return 'p2wpkh';
          }
          if (type.contains('scripthash')) {
            return 'p2sh-p2wpkh';
          }
          if (type.contains('pubkeyhash')) {
            return 'p2pkh';
          }
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
      if (topAddr != null && topAddr.isNotEmpty) {
        return inferInputScriptFromAddress(topAddr, defaultScript: defaultScript);
      }
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

  /// Estimates the transaction fee in BTC given a list of [utxos] as inputs.
  ///
  /// Infers the script type per UTXO from its address (falling back to
  /// [inputScript]) to compute per-input vsize. Calls `estimatesmartfee` RPC
  /// for the current fee rate, then the Esplora `/fee-estimates` endpoint
  /// ([esploraBaseUrl] override, else `BITCOIN_ESPLORA_URL`) if the RPC is
  /// unavailable; falls back to [fallbackRateSatsPerVbyte] only if both fail.
  Future<double> estimateFeeByInputs({
    int numOutputs = 2,
    int confTarget = 6,
    String inputScript = 'p2wpkh', // 'p2pkh', 'p2wpkh', 'p2sh-p2wpkh', 'p2tr'
    double fallbackRateSatsPerVbyte = 50.0,
    List<Utxo>? utxos,
    String? esploraBaseUrl,
  }) async {
    // Determine inputs and compute total input vsize (infer from utxos if provided)
    int inputs = (utxos != null && utxos.isNotEmpty) ? utxos.length : 1;

    try {
      final feeRateSatsPerVbyte = await _getFeeRateSatsPerVbyte(
          confTarget, fallbackRateSatsPerVbyte,
          esploraBaseUrl: esploraBaseUrl);

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
          final chosenScript = inferInputScriptFromAddress(u.address, defaultScript: inputScript);
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
          final chosenScript = inferInputScriptFromAddress(u.address, defaultScript: inputScript);
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

  /// Estimates the transaction fee in BTC for a transaction with [numInputs]
  /// inputs and [numOutputs] outputs of type [inputScript].
  ///
  /// Calls `estimatesmartfee` RPC for [confTarget] blocks, then the Esplora
  /// `/fee-estimates` endpoint ([esploraBaseUrl] override, else
  /// `BITCOIN_ESPLORA_URL`) if the RPC is unavailable; falls back to
  /// [fallbackRateSatsPerVbyte] only if both fail.
  /// Throws [ArgumentError] if [numInputs] is not positive.
  Future<double> estimateFee({
    required int numInputs,
    int numOutputs = 2,
    int confTarget = 6,
    String inputScript = 'p2wpkh', // 'p2pkh', 'p2wpkh', 'p2sh-p2wpkh', 'p2tr'
    double fallbackRateSatsPerVbyte = 50.0,
    String? esploraBaseUrl,
  }) async {
    if (numInputs <= 0) {
      throw ArgumentError('numInputs must be > 0');
    }

    try {
      final feeRateSatsPerVbyte = await _getFeeRateSatsPerVbyte(
          confTarget, fallbackRateSatsPerVbyte,
          esploraBaseUrl: esploraBaseUrl);

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

    if (result is! List) {
      return <Utxo>[];
    }

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

  /// Uses the provided list of `Utxo` objects as inputs for the created transaction.
  Future<String> sendTransferUsingUtxos(
    String toAddress,
    double amount,
    List<Utxo> utxos, {
    List<String>? privKeysWif,
    double fee = 0.0001,
    required String changeAddress,
  }) async {
    if (utxos.isEmpty) {
      throw ArgumentError('UTXOs list must not be empty');
    }
    if (changeAddress.isEmpty) {
      throw ArgumentError('changeAddress must not be empty');
    }

    // Build inputs array and sum input amounts using Utxo model
    final List<Map<String, dynamic>> inputs = utxos.map((u) => u.toRpcInput()).toList();
    final double totalIn = utxos.fold(0.0, (double sum, Utxo u) => sum + u.amount);
    final String changeAddr = changeAddress;

    // Compute change and handle dust
    // Use integer arithmetic (satoshis) to avoid floating point rounding issues
    const int dustThresholdSats = 546; // sats
    final int totalInSats = (totalIn * 1e8).round();
    final int amountSats = (amount * 1e8).round();
    final int feeSats = (fee * 1e8).round();
    final int changeSats = totalInSats - amountSats - feeSats;

    if (changeSats < 0) {
      throw Exception('Insufficient funds: inputs ${totalIn} < amount ${amount} + fee ${fee}');
    }

    // Build outputs map (RPC expects BTC amounts as doubles). Convert sats back to BTC
    final Map<String, dynamic> outputs = {toAddress: amount};
    if (changeSats > dustThresholdSats) {
      final double changeBtc = changeSats / 1e8;
      outputs[changeAddr] = double.parse(changeBtc.toStringAsFixed(8));
    } // else treat change as additional fee

    // Create raw transaction
    final raw = await _callRpc('createrawtransaction', [inputs, outputs]);
    String rawHex;
    if (raw is String) {
      rawHex = raw;
    } else if (raw is Map<String, dynamic> && raw.containsKey('hex')) {
      rawHex = raw['hex'] as String;
    } else {
      throw Exception('createrawtransaction returned unexpected result: $raw');
    }

    // Sign with wallet or offline using provided WIF keys
    String signedHex;
    if (privKeysWif != null && privKeysWif.isNotEmpty) {
      // Try offline signing using provided WIF keys and the UTXOs info
      try {
        signedHex = await _signRawTransactionOffline(rawHex, utxos, privKeysWif);
      } catch (e) {
        log.warning('Offline signing failed, falling back to wallet RPC: $e');
        final signed = await _callRpc('signrawtransactionwithwallet', [rawHex]);
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
      }
    } else {
      // Default behaviour: use wallet to sign
      final signed = await _callRpc('signrawtransactionwithwallet', [rawHex]);
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
    }

    // Broadcast
    final sendResult = await _callRpc('sendrawtransaction', [signedHex]);
    if (sendResult is String) {
      return sendResult;
    }
    if (sendResult is Map<String, dynamic> && sendResult.containsKey('txid')) {
      return sendResult['txid'] as String;
    }
    return sendResult.toString();
  }

  /// Attempt to sign [rawHex] offline using provided [wifs] (WIF private keys) and
  /// information contained in [utxos] (scriptPubKey and amount when available).
  ///
  /// This method attempts to support common input types (P2PKH, P2WPKH, P2SH-P2WPKH)
  /// using the bundled `dartsv`/`bitcoin_base` helpers. It is intentionally
  /// best-effort: if signing cannot be completed the method throws.
  ///
  /// The actual EC signing math is CPU-heavy (ECDSA sign per input) and runs on
  /// a background isolate via [compute] so it doesn't freeze the UI thread.
  Future<String> _signRawTransactionOffline(
      String rawHex, List<Utxo> utxos, List<String> wifs) async {
    try {
      return await compute(_signRawTransactionOfflineIsolate, {
        'rawHex': rawHex,
        'utxos': utxos.map((u) => u.toMap()).toList(),
        'wifs': wifs,
      });
    } catch (e) {
      throw Exception('Offline signing failed: $e');
    }
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
    if (amount <= 0) {
      throw ArgumentError('amount must be > 0');
    }

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
    utxos = utxos.where((u) => u.spendable == null || (u.spendable ?? false)).toList();

    if (utxos.isEmpty) {
      throw Exception('No available UTXOs');
    }

    // First try: see if a single UTXO can cover amount + fee (using that UTXO's script)
    // We'll compute per-candidate fee and pick the smallest UTXO that satisfies it.
    Utxo? singleCandidate;
    // Sort ascending to prefer smaller single utxo when possible
    final asc = List<Utxo>.from(utxos)..sort((a, b) => a.amount.compareTo(b.amount));
    // Use integer sats for comparison to avoid floating rounding
    final int amountSatsTarget = (amount * 1e8).round();
    for (final u in asc) {
      final script = inferInputScriptFromUtxo(u.toMap(), defaultScript: defaultInputScript);
      final fee = await estimateFee(
          numInputs: 1,
          numOutputs: numOutputs,
          confTarget: confTarget,
          inputScript: script,
          fallbackRateSatsPerVbyte: fallbackRateSatsPerVbyte);
      final int feeSats = (fee * 1e8).round();
      final int uSats = (u.amount * 1e8).round();
      if (uSats >= amountSatsTarget + feeSats) {
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
    int selectedSumSats = 0;

    for (final u in desc) {
      selected.add(u);
      selectedSumSats += (u.amount * 1e8).round();

      // Estimate fee for the currently selected inputs using estimateFeeByInputs which
      // can accept the utxos list to infer per-input script type.
      final fee = await estimateFeeByInputs(
        numOutputs: numOutputs,
        confTarget: confTarget,
        utxos: selected,
        fallbackRateSatsPerVbyte: fallbackRateSatsPerVbyte,
      );

      final int feeSatsNow = (fee * 1e8).round();
      if (selectedSumSats >= amountSatsTarget + feeSatsNow) {
        return selected;
      }
    }

    // If we reach here, funds are insufficient
    throw Exception(
        'Insufficient funds: available ${utxos.fold(0.0, (p, e) => p + e.amount)} BTC, required ${amount} BTC plus fees');
  }

  /// Calculate fee for a given confirmation target (number of blocks).
  ///
  /// Calls `estimatesmartfee` RPC to obtain a fee rate for `confTarget`
  /// (blocks), then the Esplora `/fee-estimates` endpoint ([esploraBaseUrl]
  /// override, else `BITCOIN_ESPLORA_URL`) if the RPC is unavailable, then
  /// [fallbackRateSatsPerVbyte] only if both fail. Then computes an estimated
  /// transaction vsize and fee (in BTC and sats).
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
    String? esploraBaseUrl,
  }) async {
    if (confTarget <= 0) {
      throw ArgumentError('confTarget must be > 0');
    }
    if (numInputs <= 0 && (utxos == null || utxos.isEmpty)) {
      throw ArgumentError('Provide numInputs > 0 or a non-empty utxos list');
    }

    // Determine fee rate (sats/vbyte): estimatesmartfee RPC, then Esplora
    // /fee-estimates, then the provided fallback rate — see
    // _getFeeRateSatsPerVbyte.
    final feeRateSatsPerVbyte = await _getFeeRateSatsPerVbyte(
        confTarget, fallbackRateSatsPerVbyte,
        esploraBaseUrl: esploraBaseUrl);

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
        final chosenScript = inferInputScriptFromAddress(u.address, defaultScript: inputScript);
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

  /// Determines the current fee rate in sats/vbyte for [confTarget] blocks.
  ///
  /// Tries Bitcoin Core RPC `estimatesmartfee` first. If that errors, times
  /// out, or returns no usable `feerate` (e.g. the node has insufficient
  /// mempool data and reports `errors` instead), falls back to the
  /// Esplora-compatible `/fee-estimates` REST endpoint — Esplora is already a
  /// hard dependency for balance/UTXO discovery, so this keeps fee estimation
  /// working even when the RPC endpoint alone is degraded or unreachable.
  /// Only falls back to the hardcoded [fallbackRateSatsPerVbyte] if both
  /// sources fail.
  Future<double> _getFeeRateSatsPerVbyte(
    int confTarget,
    double fallbackRateSatsPerVbyte, {
    String? esploraBaseUrl,
  }) async {
    try {
      final result = await _callRpc('estimatesmartfee', [confTarget]);
      if (result is Map && result.containsKey('feerate')) {
        final feerate = result['feerate'];
        final feerateBtcPerKb = feerate is num
            ? feerate.toDouble()
            : double.tryParse(feerate?.toString() ?? '') ?? 0.0;
        if (feerateBtcPerKb > 0) {
          return feerateBtcPerKb * 1e8 / 1000.0;
        }
      } else if (result is Map && result.containsKey('errors')) {
        final errs = result['errors'];
        if (errs is List && errs.isNotEmpty) {
          log.warning('estimatesmartfee returned errors: $errs — trying Esplora fallback');
        }
      }
    } catch (e) {
      log.warning('estimatesmartfee RPC failed: $e — trying Esplora fallback');
    }

    final esploraRate = await _fetchEsploraFeeRate(confTarget, baseUrl: esploraBaseUrl);
    if (esploraRate != null && esploraRate > 0) {
      return esploraRate;
    }

    return fallbackRateSatsPerVbyte;
  }

  /// Fetches a fee rate (sats/vbyte) for [confTarget] blocks from the
  /// Esplora-compatible `/fee-estimates` endpoint (mempool.space /
  /// blockstream.info format: `{"1": 87.1, "2": 65.4, ..., "144": 1.0}`,
  /// keyed by confirmation target in blocks). Returns null on any error or if
  /// Esplora isn't configured, so [_getFeeRateSatsPerVbyte] can fall back
  /// further rather than throwing.
  Future<double?> _fetchEsploraFeeRate(int confTarget, {String? baseUrl}) async {
    try {
      final envValue = dotenv.isInitialized ? dotenv.env['BITCOIN_ESPLORA_URL'] : null;
      final base = (baseUrl ?? envValue ?? '').trim();
      if (base.isEmpty) {
        return null;
      }
      final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      final resp = await http.get(Uri.parse('$normalizedBase/fee-estimates'),
          headers: const {'Accept': 'application/json'});
      // mempool.space returns 203 (Non-Authoritative Information) rather than
      // 200 for this specific endpoint — accept any 2xx, not just exactly 200.
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) {
        return null;
      }
      // Not every confirmation target is present — pick the closest available
      // target that is >= confTarget (prefer a slightly slower confirmation
      // over a faster/pricier one the caller didn't ask for), or the largest
      // available target otherwise.
      final targets = decoded.keys.map((k) => int.tryParse(k.toString())).whereType<int>().toList()
        ..sort();
      if (targets.isEmpty) {
        return null;
      }
      final chosenTarget = targets.firstWhere((t) => t >= confTarget, orElse: () => targets.last);
      final rate = decoded[chosenTarget.toString()];
      return rate is num ? rate.toDouble() : double.tryParse(rate?.toString() ?? '');
    } catch (e) {
      log.warning('Esplora fee-estimates fallback failed: $e');
      return null;
    }
  }

  String _resolveEsploraBaseUrl(String? override) {
    final envValue = dotenv.isInitialized ? dotenv.env['BITCOIN_ESPLORA_URL'] : null;
    final base = (override ?? envValue ?? '').trim();
    if (base.isEmpty) {
      throw ArgumentError('BITCOIN_ESPLORA_URL must be configured '
          '(Esplora-compatible REST API base URL, e.g. mempool.space or blockstream.info)');
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  /// Fetch the UTXO set for [address] from an Esplora-compatible REST API
  /// (mempool.space / blockstream.info format): `GET {base}/address/{address}/utxo`.
  /// Unlike a raw transaction scan, this endpoint is already filtered to this
  /// address's unspent outputs, so every entry returned is safe to spend.
  Future<List<Utxo>> fetchUtxosFromEsplora(String address, {String? baseUrl}) async {
    if (address.isEmpty) {
      throw ArgumentError('address must not be empty');
    }

    final base = _resolveEsploraBaseUrl(baseUrl);
    final uri = Uri.parse('$base/address/$address/utxo');
    final resp = await http.get(uri, headers: const {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Esplora HTTP ${resp.statusCode}: ${resp.body}');
    }

    final body = jsonDecode(resp.body);
    if (body is! List) {
      return <Utxo>[];
    }

    // Esplora's UTXO entries only carry the block height they confirmed in,
    // not a confirmation count — fetch the current tip once so real
    // confirmation counts (not just a confirmed/unconfirmed flag) can be
    // shown to help the user pick which UTXO to spend.
    int? tipHeight;
    try {
      final tipResp = await http.get(Uri.parse('$base/blocks/tip/height'));
      if (tipResp.statusCode == 200) {
        tipHeight = int.tryParse(tipResp.body.trim());
      }
    } catch (_) {
      // Fall back to the confirmed/unconfirmed flag below if this fails.
    }

    return body
        .whereType<Map<String, dynamic>>()
        .where((item) => item.containsKey('txid') && item['txid'] is String)
        .map((item) {
      final rawValue = item['value'];
      final int sats = rawValue is num ? rawValue.toInt() : int.tryParse('$rawValue') ?? 0;
      final statusRaw = item['status'];
      final Map<String, dynamic>? status = statusRaw is Map<String, dynamic> ? statusRaw : null;
      final bool confirmed = status?['confirmed'] == true;
      final int? blockHeight =
          status?['block_height'] is int ? status!['block_height'] as int : null;
      final int? blockTimeSec = status?['block_time'] is int ? status!['block_time'] as int : null;

      final int confirmations = !confirmed
          ? 0
          : (tipHeight != null && blockHeight != null ? tipHeight - blockHeight + 1 : 1);

      return Utxo(
        txid: item['txid'] as String,
        vout: item['vout'] is int ? item['vout'] as int : int.parse('${item['vout']}'),
        amount: sats / 1e8,
        address: address,
        scriptPubKey: _p2pkhScriptPubKeyHexFromAddress(address),
        confirmations: confirmations,
        spendable: true,
        confirmedAt:
            blockTimeSec != null ? DateTime.fromMillisecondsSinceEpoch(blockTimeSec * 1000) : null,
      );
    }).toList();
  }

  /// Derives the P2PKH scriptPubKey hex (`76a914<hash160>88ac`) from a
  /// base58check legacy address. Esplora's UTXO endpoint doesn't return
  /// scriptPubKey, but offline signing needs it to build the output being
  /// spent. Returns null for bech32 addresses (not produced by this wallet).
  String? _p2pkhScriptPubKeyHexFromAddress(String address) {
    if (address.startsWith('bc1') || address.startsWith('tb1')) {
      return null;
    }
    try {
      final decoded = _base58Decode(address);
      if (decoded.length != 25) {
        return null;
      }
      final hash160 = decoded.sublist(1, 21);
      final hash160Hex = hash160.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '76a914${hash160Hex}88ac';
    } catch (_) {
      return null;
    }
  }

  static const _base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  Uint8List _base58Decode(String input) {
    BigInt num = BigInt.zero;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = _base58Alphabet.indexOf(char);
      if (index == -1) {
        throw FormatException('Invalid base58 character: $char');
      }
      num = num * BigInt.from(58) + BigInt.from(index);
    }

    final bytes = <int>[];
    while (num > BigInt.zero) {
      bytes.insert(0, (num % BigInt.from(256)).toInt());
      num = num ~/ BigInt.from(256);
    }

    for (final rune in input.runes) {
      if (String.fromCharCode(rune) == '1') {
        bytes.insert(0, 0);
      } else {
        break;
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Fetch the current balance (confirmed + unconfirmed) for [address] from an
  /// Esplora-compatible REST API: `GET {base}/address/{address}`.
  Future<double> fetchBalanceFromEsplora(String address, {String? baseUrl}) async {
    if (address.isEmpty) {
      throw ArgumentError('address must not be empty');
    }

    final base = _resolveEsploraBaseUrl(baseUrl);
    final uri = Uri.parse('$base/address/$address');
    final resp = await http.get(uri, headers: const {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Esplora HTTP ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw FormatException(
          'Esplora /address response is not a JSON object: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}');
    }
    final chain = data['chain_stats'] as Map<String, dynamic>? ?? const {};
    final mempool = data['mempool_stats'] as Map<String, dynamic>? ?? const {};

    int sats(Map<String, dynamic> m, String key) => (m[key] is num) ? (m[key] as num).toInt() : 0;

    final int balanceSats = sats(chain, 'funded_txo_sum') -
        sats(chain, 'spent_txo_sum') +
        sats(mempool, 'funded_txo_sum') -
        sats(mempool, 'spent_txo_sum');

    return balanceSats / 1e8;
  }
}

/// Runs the actual offline-signing CPU work (ECDSA sign per input) for
/// [BitcoinNodeClient._signRawTransactionOffline]. Must be a top-level
/// function so it can be dispatched to a background isolate via [compute].
String _signRawTransactionOfflineIsolate(Map<String, dynamic> args) {
  final rawHex = args['rawHex'] as String;
  final utxos =
      (args['utxos'] as List).cast<Map<String, dynamic>>().map((m) => Utxo.fromMap(m)).toList();
  final wifs = (args['wifs'] as List).cast<String>();

  final tx = dartsv.Transaction.fromHex(rawHex);

  final List<dartsv.TransactionSigner> signers = [];
  for (final w in wifs) {
    try {
      final svPriv = dartsv.SVPrivateKey.fromWIF(w);
      signers.add(dartsv.TransactionSigner(1, svPriv));
    } catch (_) {
      // Invalid WIF, skip it.
    }
  }

  if (signers.isEmpty) {
    throw Exception('No valid WIF keys provided');
  }

  for (var i = 0; i < tx.inputs.length; i++) {
    final input = tx.inputs[i];

    Utxo? match;
    for (final u in utxos) {
      if (u.txid.toLowerCase() == input.prevTxnId.toLowerCase() &&
          u.vout == input.prevTxnOutputIndex) {
        match = u;
        break;
      }
    }

    if (match == null) {
      throw Exception('Missing UTXO information for input index $i');
    }

    final valueSats = (match.amount * 1e8).round();
    final scriptHex = match.scriptPubKey ?? '';
    if (scriptHex.isEmpty) {
      throw Exception('Missing scriptPubKey for input $i; cannot sign offline');
    }
    final outScript = dartsv.SVScript.fromHex(scriptHex);

    bool signed = false;
    for (final signer in signers) {
      try {
        // dartsv's default input unlock builder just echoes back whatever
        // script it last saw (including the sighash preimage's temporary
        // subscript), so it never produces a real `<sig><pubkey>` scriptSig.
        // Attach a P2PKHUnlockBuilder *before* signing so the signature
        // actually gets assembled into the final scriptSig.
        tx.inputs[i] = dartsv.TransactionInput(
          input.prevTxnId,
          input.prevTxnOutputIndex,
          input.sequenceNumber,
          scriptBuilder: dartsv.P2PKHUnlockBuilder(signer.signingKey.publicKey),
        );

        final utxoOutput = dartsv.TransactionOutput(BigInt.from(valueSats), outScript);
        signer.sign(tx, utxoOutput, i);
        signed = true;
        break;
      } catch (_) {
        // try next signer
      }
    }

    if (!signed) {
      throw Exception('Failed to sign input $i with provided keys');
    }
  }

  return tx.serialize();
}
