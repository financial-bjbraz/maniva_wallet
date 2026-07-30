// test/integration/bitcoin_transfer_integration_test.dart
//
// Real testnet3 Bitcoin transfer — hits live Esplora/RPC endpoints and
// broadcasts an actual (though worthless) testnet3 transaction each run.
// Tagged 'integration' so a plain `flutter test` never runs it — see
// dart_test.yaml, which skips this tag by default.
//
// ── Run explicitly ──────────────────────────────────────────────────────
//   flutter test --tags integration --run-skipped test/integration/
//
// ── Prerequisite ────────────────────────────────────────────────────────
// The address derived from _kPrivKeyHex needs testnet3 balance. Fund it via
// a faucet, e.g. https://coinfaucet.eu/en/btc-testnet/ — the test prints its
// own source address on each run.
// ───────────────────────────────────────────────────────────────────────────

@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maniva_wallet/entities/bitcoin_utxo.dart';
import 'package:maniva_wallet/services/bitcoin_service.dart';
import 'package:maniva_wallet/util/bitcoin.dart';

/// Test-only private key (from .env's PRIVATE_KEY) — testnet3 only, never use
/// this on mainnet.
const _kPrivKeyHex = 'd55cc123c161da6c85f6d65ec33fb6c53cc2d22da3b637f3ad275fc0ceaf76fb';

/// Destination for the integration transfer — a real testnet3 address (the
/// mainnet address originally supplied by the user can't be used here).
const _kIntegrationDestination = 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546';

const _kRealAmountBtc = 0.00001;

const _kTestnetRpcUrl = 'https://bitcoin-testnet-rpc.publicnode.com';

const _kEsploraTestnetUrl = 'https://mempool.space/testnet/api';

String _hexToWif(String hexKey, {bool testnet = true, bool compressed = true}) {
  final keyBytes = _hexToBytes(hexKey);
  final prefix = testnet ? 0xEF : 0x80;
  final payload = <int>[prefix, ...keyBytes, if (compressed) 0x01];
  final h1 = sha256.convert(payload).bytes;
  final h2 = sha256.convert(h1).bytes;
  final checksum = h2.sublist(0, 4);
  return _base58Encode(Uint8List.fromList([...payload, ...checksum]));
}

Uint8List _hexToBytes(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    out[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return out;
}

String _base58Encode(Uint8List data) {
  const alpha = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var n = BigInt.parse(data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
  var result = '';
  while (n > BigInt.zero) {
    final mod = n % BigInt.from(58);
    result = alpha[mod.toInt()] + result;
    n ~/= BigInt.from(58);
  }
  for (final b in data) {
    if (b == 0) {
      result = '1$result';
    } else {
      break;
    }
  }
  return result;
}

void main() {
  group('Integração – transferência real testnet3', () {
    test('transfere 0.00001 BTC na testnet3 usando assinatura offline', () async {
      // ── Derivar endereço e WIF da PRIVATE_KEY ────────────────────────────
      final wif = _hexToWif(_kPrivKeyHex, testnet: true, compressed: true);
      // Endereço P2PKH testnet3 (m... ou n...) – usado para buscar UTXOs via scantxoutset
      final sourceAddr = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x6F);

      // ignore: avoid_print
      print('WIF (testnet): $wif');
      // ignore: avoid_print
      print('Endereço de origem P2PKH testnet3: $sourceAddr');
      // ignore: avoid_print
      print('Faucet: https://coinfaucet.eu/en/btc-testnet/');

      // ── Buscar UTXOs via Esplora (sem wallet) ─────────────────────────────
      // Nota: `scantxoutset`/`listunspent` são rejeitados por nós RPC públicos
      // (exigem uma wallet carregada no servidor), por isso a descoberta de
      // UTXOs usa a mesma API REST estilo Esplora que a produção usa.
      final client = BitcoinNodeClient(rpcUrl: _kTestnetRpcUrl);
      List<Utxo> utxos;
      try {
        utxos = await client.fetchUtxosFromEsplora(sourceAddr, baseUrl: _kEsploraTestnetUrl);
      } catch (e) {
        markTestSkipped('Não foi possível conectar ao Esplora: $e');
        return;
      }

      if (utxos.isEmpty) {
        markTestSkipped(
          'Nenhum UTXO encontrado para $sourceAddr.\n'
          'Abasteça o endereço em: https://coinfaucet.eu/en/btc-testnet/',
        );
        return;
      }

      final totalBtc = utxos.fold<double>(0, (s, u) => s + u.amount);
      const feeBtc = 0.00001; // 1000 sats – suficiente para testnet3
      final minRequired = _kRealAmountBtc + feeBtc;

      // ignore: avoid_print
      print('Total disponível: $totalBtc BTC');

      expect(
        totalBtc,
        greaterThanOrEqualTo(minRequired),
        reason: 'Saldo insuficiente: $totalBtc BTC (necessário: $minRequired BTC)',
      );

      // ── Enviar transação real com assinatura offline ───────────────────────
      final txid = await client.sendTransferUsingUtxos(
        _kIntegrationDestination,
        _kRealAmountBtc,
        utxos,
        fee: feeBtc,
        changeAddress: sourceAddr, // troco volta para o endereço de origem
        privKeysWif: [wif],
      );

      expect(txid, isNotEmpty, reason: 'A transação deve retornar um txid válido');

      // ignore: avoid_print
      print('✅ Transação enviada! txid: $txid');
      // ignore: avoid_print
      print('🔍 Explorer: https://mempool.space/testnet/tx/$txid');
    });
  });
}
