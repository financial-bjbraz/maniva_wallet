// test/bitcoin_transfer_test.dart
//
// Testes unitários (mockados) e de integração (testnet3 real) para todas as
// operações de transferência Bitcoin do BitcoinNodeClient.
//
// ─── Endereços de destino ────────────────────────────────────────────────────
// O usuário forneceu: bc1qdse2pw0avfh200at0phyhqm8fq3hespa8ehf5y
// ATENÇÃO: esse endereço usa o prefixo bc1q → endereço MAINNET Bitcoin.
// Nós testnet3 rejeitam endereços mainnet. Para transações reais em testnet3
// é necessário um endereço com prefixo tb1q / tb1p / m / n / 2.
// Os testes abaixo usam endereços testnet3 válidos.
//
// ─── Execução ────────────────────────────────────────────────────────────────
// Todos os testes (mockados):
//   flutter test test/bitcoin_transfer_test.dart
//
// Apenas testes de integração (transação real na testnet3):
//   flutter test test/bitcoin_transfer_test.dart --tags integration
//
// ─── Pré-requisito para integração ──────────────────────────────────────────
// O endereço derivado da PRIVATE_KEY do .env precisa ter saldo testnet3.
// Use um faucet, por exemplo: https://coinfaucet.eu/en/btc-testnet/
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maniva_wallet/entities/bitcoin_utxo.dart';
import 'package:maniva_wallet/services/bitcoin_service.dart';
import 'package:maniva_wallet/util/bitcoin.dart';

// ─── Configuração de teste ────────────────────────────────────────────────────

/// Chave privada de teste extraída do arquivo .env (PRIVATE_KEY).
/// Esta conta é somente para testnet – nunca use em mainnet.
const _kPrivKeyHex = 'd55cc123c161da6c85f6d65ec33fb6c53cc2d22da3b637f3ad275fc0ceaf76fb';

/// Endereço testnet3 principal usado nos testes mockados.
/// Corresponde ao scriptPubKey 0014a4528547945a44c365d8cb92dbb644ffaaf510f2 (P2WPKH).
const _kAddrTestnet = 'tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546';

/// Segundo endereço testnet3, usado como `changeAddress` em testes que
/// precisam diferenciar o output de troco do output de destino.
const _kChangeAddrTestnet = 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx';

/// Endereço mainnet fornecido pelo usuário (apenas para referência – não pode
/// ser usado em testnet3).
const _kAddrMainnetRef = 'bc1qdse2pw0avfh200at0phyhqm8fq3hespa8ehf5y';

/// Nó público testnet3. Suporta createrawtransaction / sendrawtransaction
/// sem autenticação de carteira.
const _kTestnetRpcUrl = 'https://bitcoin-testnet-rpc.publicnode.com';

/// API REST estilo Esplora (mempool.space) usada para descobrir UTXOs sem
/// depender de uma wallet carregada no nó (que os provedores públicos não
/// expõem – `listunspent`/`scantxoutset` são rejeitados por eles).
const _kEsploraTestnetUrl = 'https://mempool.space/testnet/api';

// ─── Helpers de criptografia ──────────────────────────────────────────────────

/// Converte uma chave privada hex em formato WIF (Wallet Import Format).
/// testnet=true  → prefixo 0xEF → começa com 'c' (comprimida) ou '9' (não-comprimida).
/// testnet=false → prefixo 0x80 → começa com 'K'/'L' (comprimida) ou '5' (não-comprimida).
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

// ─── Fábrica de RPC falso (mocked) ───────────────────────────────────────────

Future<dynamic> Function(String, [List<dynamic>?]) _mockRpc({
  String changeAddress = _kAddrTestnet,
  String rawHex = '0200000001aabbccdd00',
  String signedHex = '0200000001aabbccsigned',
  String txid = 'faketxid0000000000000000000000000000000000000000000000000000000001',
  double feeRateBtcPerKb = 0.00010000,
  List<Map<String, dynamic>> unspent = const [],
}) =>
    (String method, [List<dynamic>? params]) async {
      switch (method) {
        case 'getrawchangeaddress':
          return changeAddress;
        case 'createrawtransaction':
          return rawHex;
        case 'signrawtransactionwithwallet':
          return {'hex': signedHex, 'complete': true};
        case 'sendrawtransaction':
          return txid;
        case 'estimatesmartfee':
          return {'feerate': feeRateBtcPerKb};
        case 'listunspent':
          return unspent;
        case 'scantxoutset':
          return {
            'success': true,
            'unspents': unspent,
            'total_amount':
                unspent.fold<double>(0.0, (s, u) => s + (u['amount'] as num).toDouble()),
          };
        default:
          throw UnimplementedError('Método RPC não esperado: $method');
      }
    };

// ─── Fábrica de Utxo ──────────────────────────────────────────────────────────

Utxo _utxo({
  String txid = 'aaaa000000000000000000000000000000000000000000000000000000000001',
  int vout = 0,
  double amount = 0.001,
  String address = _kAddrTestnet,
  String scriptPubKey = '0014a4528547945a44c365d8cb92dbb644ffaaf510f2',
  int confirmations = 6,
  bool spendable = true,
}) =>
    Utxo(
      txid: txid,
      vout: vout,
      amount: amount,
      address: address,
      scriptPubKey: scriptPubKey,
      confirmations: confirmations,
      spendable: spendable,
    );

BitcoinNodeClient _client({
  Future<dynamic> Function(String, [List<dynamic>?])? rpcOverride,
}) =>
    BitcoinNodeClient(
      rpcUrl: 'http://127.0.0.1:18332',
      rpcUser: 'u',
      rpcPassword: 'p',
      rpcCallOverride: rpcOverride ?? _mockRpc(),
    );

// ─── Suíte de testes ──────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════════
  // 1. inferInputScriptFromAddress
  // ══════════════════════════════════════════════════════════════════════════════
  group('inferInputScriptFromAddress', () {
    final c = _client();

    test('tb1q → p2wpkh (native SegWit testnet)', () {
      expect(c.inferInputScriptFromAddress('tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546'), 'p2wpkh');
    });

    test('bc1q → p2wpkh (native SegWit mainnet)', () {
      expect(c.inferInputScriptFromAddress('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'), 'p2wpkh');
    });

    test('bc1q fornecido pelo usuário → p2wpkh', () {
      expect(c.inferInputScriptFromAddress(_kAddrMainnetRef), 'p2wpkh');
    });

    test('tb1p → p2tr (Taproot testnet)', () {
      expect(
          c.inferInputScriptFromAddress(
              'tb1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqghxy6w'),
          'p2tr');
    });

    test('bc1p → p2tr (Taproot mainnet)', () {
      expect(
          c.inferInputScriptFromAddress(
              'bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqz4dv4e'),
          'p2tr');
    });

    test('2... → p2sh-p2wpkh (P2SH testnet)', () {
      expect(c.inferInputScriptFromAddress('2N1rjhumXA3ephU4G97YkFRFyDMuBnQY6T5'), 'p2sh-p2wpkh');
    });

    test('3... → p2sh-p2wpkh (P2SH mainnet)', () {
      expect(c.inferInputScriptFromAddress('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'), 'p2sh-p2wpkh');
    });

    test('1... → p2pkh (legacy mainnet)', () {
      expect(c.inferInputScriptFromAddress('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2'), 'p2pkh');
    });

    test('m... → p2pkh (legacy testnet, prefixo desta wallet)', () {
      expect(c.inferInputScriptFromAddress('mfjKbRTeJMMsn9EY1Do9B4yj8qAYnA7P6p'), 'p2pkh');
    });

    test('n... → p2pkh (legacy testnet)', () {
      expect(c.inferInputScriptFromAddress('n3GNqMveyvaPvUbH469vDRadqpJMPc84JA'), 'p2pkh');
    });

    test('null → defaultScript', () {
      expect(c.inferInputScriptFromAddress(null, defaultScript: 'p2pkh'), 'p2pkh');
    });

    test('string vazia → defaultScript', () {
      expect(c.inferInputScriptFromAddress('', defaultScript: 'p2tr'), 'p2tr');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 2. inferInputScriptFromUtxo
  // ══════════════════════════════════════════════════════════════════════════════
  group('inferInputScriptFromUtxo', () {
    final c = _client();

    test('scriptPubKey.type witness_v0_keyhash → p2wpkh', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'scriptPubKey': {'type': 'witness_v0_keyhash'},
          }),
          'p2wpkh');
    });

    test('scriptPubKey.type witness_v1_taproot → p2tr', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'scriptPubKey': {'type': 'witness_v1_taproot'},
          }),
          'p2tr');
    });

    test('scriptPubKey.type scripthash → p2sh-p2wpkh', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'scriptPubKey': {'type': 'scripthash'},
          }),
          'p2sh-p2wpkh');
    });

    test('scriptPubKey.type pubkeyhash → p2pkh', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'scriptPubKey': {'type': 'pubkeyhash'},
          }),
          'p2pkh');
    });

    test('campo address tb1q → p2wpkh (fallback por endereço)', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'address': _kAddrTestnet,
          }),
          'p2wpkh');
    });

    test('scriptPubKey.address tb1q → p2wpkh', () {
      expect(
          c.inferInputScriptFromUtxo({
            'txid': 'aa',
            'vout': 0,
            'amount': 0.001,
            'scriptPubKey': {'address': _kAddrTestnet},
          }),
          'p2wpkh');
    });

    test('mapa vazio → defaultScript', () {
      expect(c.inferInputScriptFromUtxo({}, defaultScript: 'p2pkh'), 'p2pkh');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 3. estimateFee
  // ══════════════════════════════════════════════════════════════════════════════
  group('estimateFee', () {
    test('calcula fee usando feerate do RPC', () async {
      // feerate 0.0001 BTC/kB → ~10 sats/vbyte
      // 1 P2WPKH input (68 vb) + 2 outputs (68 vb) + overhead (10 vb) = 146 vb
      // fee = ceil(146 * 10) = 1460 sats = 0.00001460 BTC
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final fee = await c.estimateFee(numInputs: 1, numOutputs: 2, inputScript: 'p2wpkh');
      expect(fee, greaterThan(0));
      expect(fee, lessThan(0.001));
    });

    test('usa fallback quando feerate ausente na resposta', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') return <String, dynamic>{};
          throw UnimplementedError(m);
        },
      );
      final fee = await c.estimateFee(numInputs: 1, fallbackRateSatsPerVbyte: 50.0);
      expect(fee, greaterThan(0));
    });

    test('usa fallback quando RPC lança exceção', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') throw Exception('RPC indisponível');
          throw UnimplementedError(m);
        },
      );
      final fee = await c.estimateFee(numInputs: 1, fallbackRateSatsPerVbyte: 20.0);
      expect(fee, greaterThan(0));
    });

    test('lança ArgumentError quando numInputs <= 0', () {
      final c = _client();
      expect(() => c.estimateFee(numInputs: 0), throwsArgumentError);
    });

    test('usa Esplora /fee-estimates quando RPC falha, antes do fallback fixo', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') throw Exception('RPC indisponível');
          throw UnimplementedError(m);
        },
      );
      // Fallback absurdamente alto — se o resultado não for próximo dele,
      // é porque a chamada real ao Esplora (rede) forneceu a taxa em vez do
      // fallback fixo.
      const absurdFallbackSatsPerVbyte = 999999.0;
      double fee;
      try {
        fee = await c.estimateFee(
          numInputs: 1,
          fallbackRateSatsPerVbyte: absurdFallbackSatsPerVbyte,
          esploraBaseUrl: _kEsploraTestnetUrl,
        );
      } catch (e) {
        markTestSkipped('Não foi possível conectar ao Esplora: $e');
        return;
      }
      final feeUsingAbsurdFallback = await c.estimateFee(
        numInputs: 1,
        fallbackRateSatsPerVbyte: absurdFallbackSatsPerVbyte,
      );
      expect(fee, lessThan(feeUsingAbsurdFallback),
          reason: 'Esplora deveria ter fornecido uma taxa real bem menor que o fallback absurdo');
    });

    test('P2PKH produz fee maior que P2WPKH (mais bytes por input)', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final feeLegacy = await c.estimateFee(numInputs: 1, inputScript: 'p2pkh');
      final feeSegwit = await c.estimateFee(numInputs: 1, inputScript: 'p2wpkh');
      expect(feeLegacy, greaterThan(feeSegwit));
    });

    test('P2TR produz fee menor que P2WPKH (57 vs 68 vbytes/input)', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final feeTaproot = await c.estimateFee(numInputs: 1, inputScript: 'p2tr');
      final feeSegwit = await c.estimateFee(numInputs: 1, inputScript: 'p2wpkh');
      expect(feeTaproot, lessThan(feeSegwit));
    });

    test('fee escala com número de inputs', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final fee1 = await c.estimateFee(numInputs: 1);
      final fee3 = await c.estimateFee(numInputs: 3);
      expect(fee3, greaterThan(fee1));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 4. estimateFeeByInputs
  // ══════════════════════════════════════════════════════════════════════════════
  group('estimateFeeByInputs', () {
    test('infere p2wpkh de endereço tb1q', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final fee = await c.estimateFeeByInputs(utxos: [_utxo()]);
      expect(fee, greaterThan(0));
    });

    test('lista vazia de utxos usa numInputs=1 como padrão', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final feeComUtxo = await c.estimateFeeByInputs(utxos: [_utxo()]);
      final feeSemUtxo = await c.estimateFeeByInputs();
      // Ambos usam 1 input p2wpkh, portanto devem ser iguais
      expect(feeComUtxo, closeTo(feeSemUtxo, 1e-10));
    });

    test('múltiplos UTXOs de tipos diferentes calculam fee combinada', () async {
      final utxos = [
        _utxo(txid: 'aa' * 32, amount: 0.001, address: _kAddrTestnet), // p2wpkh
        _utxo(
          txid: 'bb' * 32,
          vout: 1,
          amount: 0.002,
          address: 'tb1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqghxy6w',
          scriptPubKey: '',
        ), // p2tr
      ];
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final fee = await c.estimateFeeByInputs(utxos: utxos);
      expect(fee, greaterThan(0));
    });

    test('usa fallback quando RPC falha', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') throw Exception('timeout');
          throw UnimplementedError(m);
        },
      );
      final fee = await c.estimateFeeByInputs(
        utxos: [_utxo()],
        fallbackRateSatsPerVbyte: 30.0,
      );
      expect(fee, greaterThan(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 5. calculateFeeForBlocks
  // ══════════════════════════════════════════════════════════════════════════════
  group('calculateFeeForBlocks', () {
    test('retorna mapa com chaves feeBtc, feeSats, feeRateSatsPerVbyte, txVsize', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0002));
      final result = await c.calculateFeeForBlocks(
        confTarget: 3,
        numInputs: 2,
        numOutputs: 2,
      );
      expect(result, isA<Map>().having((m) => m.containsKey('feeBtc'), 'contains feeBtc', true));
      expect(result, isA<Map>().having((m) => m.containsKey('feeSats'), 'contains feeSats', true));
      expect(
          result,
          isA<Map>().having(
              (m) => m.containsKey('feeRateSatsPerVbyte'), 'contains feeRateSatsPerVbyte', true));
      expect(result, isA<Map>().having((m) => m.containsKey('txVsize'), 'contains txVsize', true));
      expect(result['feeBtc'], isA<double>());
      expect(result['feeSats'], isA<int>());
    });

    test('lança ArgumentError quando confTarget <= 0', () {
      final c = _client();
      expect(
        () => c.calculateFeeForBlocks(confTarget: 0, numInputs: 1),
        throwsArgumentError,
      );
    });

    test('lança ArgumentError quando numInputs=0 e utxos vazio', () {
      final c = _client();
      expect(
        () => c.calculateFeeForBlocks(confTarget: 6, numInputs: 0),
        throwsArgumentError,
      );
    });

    test('usa taxa de fallback quando RPC falha', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') throw Exception('indisponível');
          throw UnimplementedError(m);
        },
      );
      final result = await c.calculateFeeForBlocks(
        confTarget: 6,
        numInputs: 1,
        fallbackRateSatsPerVbyte: 20.0,
      );
      expect(result['feeBtc'], greaterThan(0));
      expect(result['feeRateSatsPerVbyte'], 20.0);
    });

    test('confirmações mais rápidas (1 bloco) têm fee maior', () async {
      final c = BitcoinNodeClient(
        rpcUrl: 'http://127.0.0.1:18332',
        rpcUser: 'u',
        rpcPassword: 'p',
        rpcCallOverride: (m, [p]) async {
          if (m == 'estimatesmartfee') {
            final target = p![0] as int;
            // Simula fee maior para confirmações mais rápidas
            return {'feerate': target == 1 ? 0.001 : 0.0001};
          }
          throw UnimplementedError(m);
        },
      );
      final fast = await c.calculateFeeForBlocks(confTarget: 1, numInputs: 1);
      final slow = await c.calculateFeeForBlocks(confTarget: 6, numInputs: 1);
      expect(fast['feeBtc'], greaterThan(slow['feeBtc'] as num));
    });

    test('aceita lista de utxos em vez de numInputs', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final result = await c.calculateFeeForBlocks(
        confTarget: 6,
        numInputs: 0,
        utxos: [_utxo(), _utxo(txid: 'bb' * 32, vout: 1)],
      );
      expect(result['feeBtc'], greaterThan(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 6. listUtxos
  // ══════════════════════════════════════════════════════════════════════════════
  group('listUtxos', () {
    test('retorna lista vazia quando RPC retorna array vazio', () async {
      final c = _client(rpcOverride: _mockRpc(unspent: []));
      expect(await c.listUtxos(_kAddrTestnet), isEmpty);
    });

    test('retorna lista vazia quando RPC não retorna List', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'listunspent') return null;
          throw UnimplementedError(m);
        },
      );
      expect(await c.listUtxos(_kAddrTestnet), isEmpty);
    });

    test('parseia campos de UTXO corretamente', () async {
      final mock = [
        {
          'txid': 'aa' * 32,
          'vout': 0,
          'amount': 0.005,
          'address': _kAddrTestnet,
          'scriptPubKey': '0014a4528547945a44c365d8cb92dbb644ffaaf510f2',
          'confirmations': 10,
          'spendable': true,
        }
      ];
      final c = _client(rpcOverride: _mockRpc(unspent: mock));
      final utxos = await c.listUtxos(_kAddrTestnet);
      expect(utxos.length, 1);
      expect(utxos[0].amount, 0.005);
      expect(utxos[0].address, _kAddrTestnet);
      expect(utxos[0].confirmations, 10);
      expect(utxos[0].spendable, true);
    });

    test('normaliza amount de String para double', () async {
      final mock = [
        {'txid': 'cc' * 32, 'vout': 0, 'amount': '0.00300000'},
      ];
      final c = _client(rpcOverride: _mockRpc(unspent: mock));
      final utxos = await c.listUtxos(_kAddrTestnet);
      expect(utxos[0].amount, closeTo(0.003, 1e-10));
    });

    test('normaliza amount de int para double', () async {
      final mock = [
        {'txid': 'dd' * 32, 'vout': 0, 'amount': 1},
      ];
      final c = _client(rpcOverride: _mockRpc(unspent: mock));
      final utxos = await c.listUtxos(_kAddrTestnet);
      expect(utxos[0].amount, 1.0);
      expect(utxos[0].amount, isA<double>());
    });

    test('parseia múltiplos UTXOs', () async {
      final mock = [
        {'txid': 'aa' * 32, 'vout': 0, 'amount': 0.001},
        {'txid': 'bb' * 32, 'vout': 1, 'amount': 0.002},
        {'txid': 'cc' * 32, 'vout': 0, 'amount': 0.003},
      ];
      final c = _client(rpcOverride: _mockRpc(unspent: mock));
      final utxos = await c.listUtxos(_kAddrTestnet);
      expect(utxos.length, 3);
      expect(utxos.map((u) => u.amount).toList(), containsAllInOrder([0.001, 0.002, 0.003]));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 7. selectUtxosForAmount
  // ══════════════════════════════════════════════════════════════════════════════
  group('selectUtxosForAmount', () {
    test('lança ArgumentError quando amount <= 0', () {
      final c = _client();
      expect(
        () => c.selectUtxosForAmount(0, availableUtxos: [_utxo()]),
        throwsArgumentError,
      );
    });

    test('lança ArgumentError sem utxos nem address', () {
      final c = _client();
      expect(() => c.selectUtxosForAmount(0.001), throwsArgumentError);
    });

    test('seleciona UTXO único quando cobre amount + fee', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final selected = await c.selectUtxosForAmount(
        0.001,
        availableUtxos: [_utxo(amount: 0.01)],
      );
      expect(selected.length, 1);
      expect(selected[0].amount, 0.01);
    });

    test('prefere UTXO menor que ainda cobre amount + fee', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final utxos = [
        _utxo(txid: 'aa' * 32, amount: 0.01),
        _utxo(txid: 'bb' * 32, vout: 1, amount: 0.005),
      ];
      final selected = await c.selectUtxosForAmount(0.002, availableUtxos: utxos);
      expect(selected.length, 1);
      // Deve escolher o menor UTXO que cobre o valor
      expect(selected[0].amount, 0.005);
    });

    test('combina múltiplos UTXOs quando nenhum cobre sozinho', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final utxos = [
        _utxo(txid: 'aa' * 32, amount: 0.0003),
        _utxo(txid: 'bb' * 32, vout: 1, amount: 0.0003),
        _utxo(txid: 'cc' * 32, vout: 2, amount: 0.0003),
      ];
      final selected = await c.selectUtxosForAmount(0.0007, availableUtxos: utxos);
      expect(selected.length, greaterThan(1));
      final sum = selected.fold<double>(0, (s, u) => s + u.amount);
      expect(sum, greaterThanOrEqualTo(0.0007));
    });

    test('lança Exception quando saldo total insuficiente', () {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      expect(
        () => c.selectUtxosForAmount(0.1, availableUtxos: [_utxo(amount: 0.00001)]),
        throwsException,
      );
    });

    test('ignora UTXOs não-gastáveis (spendable=false)', () async {
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001));
      final utxos = [
        _utxo(txid: 'aa' * 32, amount: 0.01, spendable: false),
        _utxo(txid: 'bb' * 32, vout: 1, amount: 0.01, spendable: true),
      ];
      final selected = await c.selectUtxosForAmount(0.005, availableUtxos: utxos);
      expect(selected.every((u) => u.spendable != false), true);
    });

    test('busca UTXOs via RPC listunspent quando address é fornecido', () async {
      final mock = [
        {'txid': 'aa' * 32, 'vout': 0, 'amount': 0.01, 'spendable': true},
      ];
      final c = _client(rpcOverride: _mockRpc(feeRateBtcPerKb: 0.0001, unspent: mock));
      final selected = await c.selectUtxosForAmount(0.005, address: _kAddrTestnet);
      expect(selected, isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 8. sendTransferUsingUtxos – testes mockados
  // ══════════════════════════════════════════════════════════════════════════════
  group('sendTransferUsingUtxos – mockado', () {
    test('transferência básica retorna txid', () async {
      final calls = <String>[];
      final c = _client(
        rpcOverride: (m, [p]) async {
          calls.add(m);
          return await _mockRpc()(m, p);
        },
      );
      final txid = await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.0001,
        [_utxo(amount: 0.001)],
        fee: 0.00001,
        changeAddress: _kAddrTestnet,
      );
      expect(txid, isNotEmpty);
      expect(
          calls,
          containsAll(
              ['createrawtransaction', 'signrawtransactionwithwallet', 'sendrawtransaction']));
    });

    test('changeAddress é obrigatório e não pode ser vazio', () {
      final c = _client();
      expect(
        () => c.sendTransferUsingUtxos(
          _kAddrTestnet,
          0.0001,
          [_utxo(amount: 0.001)],
          fee: 0.00001,
          changeAddress: '',
        ),
        throwsArgumentError,
      );
    });

    test('não chama getrawchangeaddress (troco é sempre fornecido pelo chamador)', () async {
      final calls = <String>[];
      final c = _client(
        rpcOverride: (m, [p]) async {
          calls.add(m);
          return await _mockRpc()(m, p);
        },
      );
      await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.0001,
        [_utxo(amount: 0.001)],
        fee: 0.00001,
        changeAddress: _kAddrTestnet,
      );
      expect(calls, isNot(contains('getrawchangeaddress')));
    });

    test('lança ArgumentError com lista de UTXOs vazia', () {
      final c = _client();
      expect(
        () => c.sendTransferUsingUtxos(_kAddrTestnet, 0.0001, [], changeAddress: _kAddrTestnet),
        throwsArgumentError,
      );
    });

    test('lança Exception quando saldo insuficiente (amount+fee > totalIn)', () {
      final c = _client();
      expect(
        () => c.sendTransferUsingUtxos(
          _kAddrTestnet,
          0.1, // muito maior que o UTXO
          [_utxo(amount: 0.00001)],
          fee: 0.00001,
          changeAddress: _kAddrTestnet,
        ),
        throwsException,
      );
    });

    test('omite output de troco quando troco < dust threshold (546 sats)', () async {
      final capturedOutputs = <Map<String, dynamic>>[];
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'createrawtransaction') {
            capturedOutputs.add(Map<String, dynamic>.from(p![1] as Map));
            return '0200000001deadbeef00';
          }
          return await _mockRpc()(m, p);
        },
      );
      // UTXO=0.00001100, amount=0.00001000, fee=0.00000500 → troco=600 sats > 546
      // Ajustando: UTXO=0.00001050, fee=0.00000500 → troco=550 sats > 546 → inclui
      // Para testar omissão: troco < 546 sats = 0.00000546
      // UTXO=0.00001000, amount=0.00000900, fee=0.00000150 → troco=−50 sats (negativo, não é o caso)
      // UTXO=0.00001000, amount=0.00000900, fee=0.00000095 → troco=5 sats < 546 → omite
      await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.00000900,
        [_utxo(amount: 0.00001000)],
        fee: 0.00000095, // troco = 5 sats < 546 sats
        changeAddress: _kAddrTestnet,
      );
      // Apenas 1 output (destinação) – sem troco
      expect(capturedOutputs.first.length, 1);
    });

    test('inclui output de troco quando troco >= dust threshold', () async {
      final capturedOutputs = <Map<String, dynamic>>[];
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'createrawtransaction') {
            capturedOutputs.add(Map<String, dynamic>.from(p![1] as Map));
            return '0200000001deadbeef00';
          }
          return await _mockRpc()(m, p);
        },
      );
      // UTXO=0.01, amount=0.001, fee=0.00001 → troco=0.00899 BTC (muito acima do dust)
      // changeAddress precisa ser diferente do destino, senão os dois outputs
      // colapsam na mesma chave do Map e o teste não consegue distinguir 1 de 2 outputs.
      await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.001,
        [_utxo(amount: 0.01)],
        fee: 0.00001,
        changeAddress: _kChangeAddrTestnet,
      );
      expect(capturedOutputs.first.length, 2); // destinação + troco
    });

    test('aceita tx assinada retornada como String (não Map)', () async {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'signrawtransactionwithwallet') return '0200000001signedstring';
          return await _mockRpc()(m, p);
        },
      );
      final txid = await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.0001,
        [_utxo(amount: 0.001)],
        fee: 0.00001,
        changeAddress: _kAddrTestnet,
      );
      expect(txid, isNotEmpty);
    });

    test('lança Exception quando assinatura falha (complete=false)', () {
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'signrawtransactionwithwallet') {
            return {'hex': '', 'complete': false};
          }
          return await _mockRpc()(m, p);
        },
      );
      expect(
        () => c.sendTransferUsingUtxos(
          _kAddrTestnet,
          0.0001,
          [_utxo(amount: 0.001)],
          fee: 0.00001,
          changeAddress: _kAddrTestnet,
        ),
        throwsException,
      );
    });

    test('múltiplos UTXOs → todos passados para createrawtransaction', () async {
      final capturedInputs = <List<dynamic>>[];
      final c = _client(
        rpcOverride: (m, [p]) async {
          if (m == 'createrawtransaction') {
            capturedInputs.add(p![0] as List<dynamic>);
            return '0200000002deadbeef00';
          }
          return await _mockRpc()(m, p);
        },
      );
      await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.00098, // deixa espaço para a fee dentro do total dos dois UTXOs (0.001)
        [
          _utxo(txid: 'aa' * 32, amount: 0.0005),
          _utxo(txid: 'bb' * 32, vout: 1, amount: 0.0005),
        ],
        fee: 0.00001,
        changeAddress: _kAddrTestnet,
      );
      expect(capturedInputs.first.length, 2);
    });

    test('passa privKeysWif → tenta assinatura offline antes do RPC', () async {
      final calls = <String>[];
      // A assinatura offline vai falhar (tx hex fake), então deve cair no fallback RPC
      final c = _client(
        rpcOverride: (m, [p]) async {
          calls.add(m);
          return await _mockRpc()(m, p);
        },
      );
      final wif = _hexToWif(_kPrivKeyHex);
      await c.sendTransferUsingUtxos(
        _kAddrTestnet,
        0.0001,
        [_utxo(amount: 0.001)],
        fee: 0.00001,
        changeAddress: _kAddrTestnet,
        privKeysWif: [wif],
      );
      // Falhou no offline → caiu no signrawtransactionwithwallet via RPC
      expect(calls, contains('signrawtransactionwithwallet'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 9. Derivação WIF a partir de chave privada hex
  // ══════════════════════════════════════════════════════════════════════════════
  group('_hexToWif – conversão de chave', () {
    test('WIF testnet comprimido começa com "c"', () {
      final wif = _hexToWif(_kPrivKeyHex, testnet: true, compressed: true);
      expect(wif.startsWith('c'), isTrue,
          reason: 'WIF testnet comprimido deve começar com c, obtido: $wif');
    });

    test('WIF mainnet comprimido começa com K ou L', () {
      final wif = _hexToWif(_kPrivKeyHex, testnet: false, compressed: true);
      expect(wif.startsWith('K') || wif.startsWith('L'), isTrue,
          reason: 'WIF mainnet comprimido deve começar com K ou L, obtido: $wif');
    });

    test('WIF tem comprimento correto (~52 caracteres para comprimido)', () {
      final wif = _hexToWif(_kPrivKeyHex);
      expect(wif.length, inInclusiveRange(51, 53));
    });

    test('WIF diferente para mainnet vs testnet', () {
      final wifTestnet = _hexToWif(_kPrivKeyHex, testnet: true);
      final wifMainnet = _hexToWif(_kPrivKeyHex, testnet: false);
      expect(wifTestnet, isNot(equals(wifMainnet)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 10. BitcoinWallet – derivação de endereço
  // ══════════════════════════════════════════════════════════════════════════════
  group('BitcoinWallet – derivação de endereço da PRIVATE_KEY', () {
    test('gera endereço P2PKH testnet3 (começa com m ou n)', () {
      // Byte de rede testnet P2PKH = 0x6F (111)
      final addr = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x6F);
      expect(addr.startsWith('m') || addr.startsWith('n'), isTrue,
          reason: 'Endereço P2PKH testnet deve começar com m ou n, obtido: $addr');
    });

    test('gera endereço P2PKH mainnet (começa com 1)', () {
      // Byte de rede mainnet P2PKH = 0x00
      final addr = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x00);
      expect(addr.startsWith('1'), isTrue,
          reason: 'Endereço P2PKH mainnet deve começar com 1, obtido: $addr');
    });

    test('endereços testnet e mainnet são diferentes', () {
      final addrTestnet = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x6F);
      final addrMainnet = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x00);
      expect(addrTestnet, isNot(equals(addrMainnet)));
    });

    test('mesma chave privada → mesmo endereço (determinístico)', () {
      final addr1 = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x6F);
      final addr2 = BitcoinWallet.generateCompressedAddress(_kPrivKeyHex, 0x6F);
      expect(addr1, equals(addr2));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 11. Utxo – modelo de dados
  // ══════════════════════════════════════════════════════════════════════════════
  group('Utxo – modelo', () {
    test('fromMap parseia todos os campos', () {
      final u = Utxo.fromMap({
        'txid': 'aabbcc' * 10 + 'aabb',
        'vout': 1,
        'amount': 0.00500000,
        'scriptPubKey': '0014abc123',
        'address': _kAddrTestnet,
        'confirmations': 3,
        'spendable': true,
      });
      expect(u.txid, isNotEmpty);
      expect(u.vout, 1);
      expect(u.amount, closeTo(0.005, 1e-10));
      expect(u.scriptPubKey, '0014abc123');
      expect(u.address, _kAddrTestnet);
      expect(u.confirmations, 3);
      expect(u.spendable, true);
    });

    test('fromMap aceita amount como String', () {
      final u = Utxo.fromMap({'txid': 'aa' * 32, 'vout': 0, 'amount': '0.00100000'});
      expect(u.amount, closeTo(0.001, 1e-10));
    });

    test('toRpcInput retorna apenas txid e vout', () {
      final u = _utxo();
      final rpc = u.toRpcInput();
      expect(rpc.keys.toList(), containsAll(['txid', 'vout']));
      expect(rpc.keys.length, 2);
    });

    test('toMap inclui todos os campos não-nulos', () {
      final u = _utxo();
      final m = u.toMap();
      expect(m, contains('txid'));
      expect(m, contains('vout'));
      expect(m, contains('amount'));
    });

    test('igualdade por txid + vout + amount + address', () {
      final a = _utxo();
      final b = _utxo();
      expect(a, equals(b));
    });

    test('copyWith atualiza campos selecionados', () {
      final original = _utxo(amount: 0.001);
      final copy = original.copyWith(amount: 0.002);
      expect(copy.amount, 0.002);
      expect(copy.txid, original.txid);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // 11. fetchUtxosFromEsplora / fetchBalanceFromEsplora
  // ══════════════════════════════════════════════════════════════════════════════
  //
  // Substitui a antiga integração com Blockbook (BLOCK_BOOK_URL, nunca
  // configurada) por uma API REST estilo Esplora (mempool.space /
  // blockstream.info), que não exige uma wallet carregada no nó e já
  // devolve o UTXO set filtrado (sem reconstrução manual de vouts).
  group('fetchUtxosFromEsplora / fetchBalanceFromEsplora', () {
    // Endereço testnet3 com UTXO confirmado conhecido (usado apenas para
    // smoke-test de integração; o teste é pulado se não houver rede).
    const _kFundedTestnetAddr = 'mfjKbRTeJMMsn9EY1Do9B4yj8qAYnA7P6p';

    test('lança ArgumentError quando BITCOIN_ESPLORA_URL não configurado', () {
      final c = BitcoinNodeClient(rpcUrl: _kTestnetRpcUrl);
      expect(() => c.fetchUtxosFromEsplora(_kFundedTestnetAddr), throwsArgumentError);
      expect(() => c.fetchBalanceFromEsplora(_kFundedTestnetAddr), throwsArgumentError);
    });

    test('lança ArgumentError quando address é vazio', () {
      final c = BitcoinNodeClient(rpcUrl: _kTestnetRpcUrl);
      expect(
          () => c.fetchUtxosFromEsplora('', baseUrl: _kEsploraTestnetUrl), throwsArgumentError);
      expect(
          () => c.fetchBalanceFromEsplora('', baseUrl: _kEsploraTestnetUrl), throwsArgumentError);
    });

    test('busca UTXOs reais via Esplora (mempool.space testnet)', () async {
      final c = BitcoinNodeClient(rpcUrl: _kTestnetRpcUrl);
      List<Utxo> utxos;
      try {
        utxos = await c.fetchUtxosFromEsplora(_kFundedTestnetAddr, baseUrl: _kEsploraTestnetUrl);
      } catch (e) {
        markTestSkipped('Não foi possível conectar ao Esplora: $e');
        return;
      }
      expect(utxos, isNotEmpty);
      expect(utxos.every((u) => u.address == _kFundedTestnetAddr), isTrue);
      expect(utxos.every((u) => u.amount > 0), isTrue);
      expect(utxos.every((u) => u.spendable == true), isTrue);
    });

    test('busca saldo real via Esplora (mempool.space testnet)', () async {
      final c = BitcoinNodeClient(rpcUrl: _kTestnetRpcUrl);
      double balance;
      try {
        balance = await c.fetchBalanceFromEsplora(_kFundedTestnetAddr, baseUrl: _kEsploraTestnetUrl);
      } catch (e) {
        markTestSkipped('Não foi possível conectar ao Esplora: $e');
        return;
      }
      expect(balance, greaterThan(0));
    });
  });

  // The real-testnet3-transfer integration test now lives in
  // test/integration/bitcoin_transfer_integration_test.dart, tagged
  // 'integration' and excluded from the default `flutter test` run (see
  // dart_test.yaml) — it used to run unconditionally and spend testnet funds
  // on every `flutter test`, despite a comment claiming --tags gated it.
}
