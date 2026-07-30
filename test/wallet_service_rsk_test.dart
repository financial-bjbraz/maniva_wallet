// test/wallet_service_rsk_test.dart
//
// Mocked unit tests for the Rootstock/ERC20 flows added to WalletServiceImpl
// (network-mode-aware RPC/token URLs, ERC20 balance/decimals/transfer, gas
// sufficiency checks) and the pure Network address-validation helpers. All
// network access is mocked via package:http/testing.dart — nothing here
// touches a real node.

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maniva_wallet/entities/wallet_helper.dart';
import 'package:maniva_wallet/services/wallet_service.dart';
import 'package:maniva_wallet/util/network.dart';

/// One canonical ERC20 token address reused across tests (checksum doesn't
/// matter for these mocked calls — no real contract is hit).
const _kTokenAddress = '0x19F64674D8A5B4E652319F5e239eFd3bc969A1fE';
const _kWalletAddress = '0x653464038eEb5df12a5343E1e30DE1B12eFA9A38';
const _kPrivateKeyHex = 'd55cc123c161da6c85f6d65ec33fb6c53cc2d22da3b637f3ad275fc0ceaf76fb';

String _hex32(BigInt value) => value.toRadixString(16).padLeft(64, '0');

/// Generic JSON-RPC mock: dispatches by method name (and, for eth_call, by
/// the ABI function selector) rather than asserting an exact call sequence,
/// since web3dart's internal ordering for reads/writes isn't a public
/// contract worth pinning tests to.
http.Client _mockRpc({
  BigInt? balanceOfResult,
  int decimalsResult = 18,
  BigInt? ethBalance,
  BigInt? gasPrice,
  bool failSendRawTransaction = false,
}) {
  return MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final method = body['method'] as String;
    final id = body['id'];
    final params = (body['params'] as List?) ?? [];

    dynamic result;
    switch (method) {
      case 'eth_chainId':
        result = '0x1f'; // 31 = Rootstock testnet
        break;
      case 'net_version':
        result = '31';
        break;
      case 'eth_getTransactionCount':
        result = '0x0';
        break;
      case 'eth_gasPrice':
        result = '0x${(gasPrice ?? BigInt.from(60000000)).toRadixString(16)}';
        break;
      case 'eth_estimateGas':
        result = '0x186a0'; // 100000
        break;
      case 'eth_getBalance':
        result = '0x${(ethBalance ?? BigInt.zero).toRadixString(16)}';
        break;
      case 'eth_blockNumber':
        result = '0x1';
        break;
      case 'eth_call':
        final callParams =
            (params.isNotEmpty ? params[0] : <String, dynamic>{}) as Map<String, dynamic>;
        final data = (callParams['data'] as String?) ?? '';
        if (data.startsWith('0x70a08231')) {
          // balanceOf(address)
          result = '0x${_hex32(balanceOfResult ?? BigInt.zero)}';
        } else if (data.startsWith('0x313ce567')) {
          // decimals()
          result = '0x${_hex32(BigInt.from(decimalsResult))}';
        } else {
          result = '0x';
        }
        break;
      case 'eth_sendRawTransaction':
        if (failSendRawTransaction) {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': id,
              'error': {'code': -32000, 'message': 'insufficient funds'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        result = '0x1111111111111111111111111111111111111111111111111111111111111111';
        break;
      default:
        result = null;
    }

    return http.Response(
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  setUpAll(() async {
    // WalletServiceImpl.rootstockNodeUrl reads dotenv — initialize it empty
    // so dotenv.env[...] lookups don't throw "not initialized".
    dotenv.testLoad(fileInput: 'ROOTSTOCK_NODE=http://localhost:9999\n');
  });

  group('Network.isValidBitcoinAddress', () {
    test('accepts mainnet formats only when isMainnet: true', () {
      expect(Network.isValidBitcoinAddress('1BoatSLRHtKNngkdXEeobR76b53LETtpyT', isMainnet: true),
          isTrue);
      expect(Network.isValidBitcoinAddress('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', isMainnet: true),
          isTrue);
      expect(
          Network.isValidBitcoinAddress('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
              isMainnet: true),
          isTrue);
    });

    test('rejects mainnet-formatted addresses when isMainnet: false', () {
      expect(Network.isValidBitcoinAddress('1BoatSLRHtKNngkdXEeobR76b53LETtpyT', isMainnet: false),
          isFalse);
      expect(
          Network.isValidBitcoinAddress('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
              isMainnet: false),
          isFalse);
    });

    test('accepts testnet formats only when isMainnet: false', () {
      expect(Network.isValidBitcoinAddress('mfjKbRTeJMMsn9EY1Do9B4yj8qAYnA7P6p', isMainnet: false),
          isTrue);
      expect(Network.isValidBitcoinAddress('n2yGXrAPUg8YMg4cA5wSsi9MEkEAMqd1c1', isMainnet: false),
          isTrue);
      expect(
          Network.isValidBitcoinAddress('tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546',
              isMainnet: false),
          isTrue);
    });

    test(
        'rejects testnet-formatted addresses when isMainnet: true — the '
        'exact cross-network mix-up this validation exists to prevent', () {
      expect(Network.isValidBitcoinAddress('n2yGXrAPUg8YMg4cA5wSsi9MEkEAMqd1c1', isMainnet: true),
          isFalse);
      expect(
          Network.isValidBitcoinAddress('tb1q53fg23u5tfzvxewcewfdhdjyl7402y8jfs0546',
              isMainnet: true),
          isFalse);
    });

    test('rejects empty/garbage input regardless of network', () {
      expect(Network.isValidBitcoinAddress('', isMainnet: true), isFalse);
      expect(Network.isValidBitcoinAddress('not-an-address', isMainnet: false), isFalse);
    });
  });

  group('Network.isValidEvmAddress', () {
    test('accepts a well-formed 0x + 40 hex char address', () {
      expect(Network.isValidEvmAddress(_kWalletAddress), isTrue);
    });

    test('rejects missing 0x prefix, wrong length, or non-hex chars', () {
      expect(Network.isValidEvmAddress(_kWalletAddress.substring(2)), isFalse);
      expect(Network.isValidEvmAddress('0x1234'), isFalse);
      expect(Network.isValidEvmAddress('0x${'g' * 40}'), isFalse);
    });
  });

  group('WalletServiceImpl network-mode getters', () {
    test(
        'currentBitcoinNetwork/currentRootstockNetwork/rootstockTokenChainId '
        'follow isMainnet', () {
      final service = WalletServiceImpl();

      service.isMainnet = false;
      expect(service.currentBitcoinNetwork, Network.BITCOIN_TESTNET);
      expect(service.currentRootstockNetwork, Network.ROOTSTOCK_TESTNET);
      expect(service.rootstockTokenChainId, 31);

      service.isMainnet = true;
      expect(service.currentBitcoinNetwork, Network.BITCOIN_MAINNET);
      expect(service.currentRootstockNetwork, Network.ROOTSTOCK_MAINNET);
      expect(service.rootstockTokenChainId, 30);
    });
  });

  group('getErc20Balance', () {
    test('returns 0 without hitting the network when a token has zero balance', () async {
      final service = WalletServiceImpl();
      final client = _mockRpc(balanceOfResult: BigInt.zero);
      final balance = await service.getErc20Balance(_kTokenAddress, _kWalletAddress,
          httpClientOverride: client);
      expect(balance, 0);
    });

    test('scales the raw balance by the token\'s decimals()', () async {
      final service = WalletServiceImpl();
      // 2.5 tokens at 18 decimals.
      final client = _mockRpc(
        balanceOfResult: BigInt.parse('2500000000000000000'),
        decimalsResult: 18,
      );
      final balance = await service.getErc20Balance(_kTokenAddress, _kWalletAddress,
          httpClientOverride: client);
      expect(balance, closeTo(2.5, 0.0000001));
    });

    test('returns 0 on RPC error instead of throwing', () async {
      final service = WalletServiceImpl();
      final failingClient = MockClient((request) async => http.Response('boom', 500));
      final balance = await service.getErc20Balance(_kTokenAddress, _kWalletAddress,
          httpClientOverride: failingClient);
      expect(balance, 0);
    });
  });

  group('getErc20Decimals', () {
    test('returns the contract\'s decimals()', () async {
      final service = WalletServiceImpl();
      final client = _mockRpc(decimalsResult: 6);
      final decimals = await service.getErc20Decimals(_kTokenAddress, httpClientOverride: client);
      expect(decimals, 6);
    });

    test('falls back to 18 on RPC error', () async {
      final service = WalletServiceImpl();
      final failingClient = MockClient((request) async => http.Response('boom', 500));
      final decimals =
          await service.getErc20Decimals(_kTokenAddress, httpClientOverride: failingClient);
      expect(decimals, 18);
    });
  });

  group('hasEnoughGasForRootstockTx', () {
    test('returns true when balance comfortably covers estimated gas', () async {
      final service = WalletServiceImpl();
      // 1 RBTC balance vs. a tiny gas requirement.
      final client = _mockRpc(
        ethBalance: BigInt.parse('1000000000000000000'),
        gasPrice: BigInt.from(60000000),
      );
      final ok = await service.hasEnoughGasForRootstockTx(_kWalletAddress,
          estimatedGasLimit: 100000, httpClientOverride: client);
      expect(ok, isTrue);
    });

    test('returns false when balance is below the required gas cost', () async {
      final service = WalletServiceImpl();
      // Balance of 1 wei can't possibly cover any nonzero gas price * limit.
      final client = _mockRpc(
        ethBalance: BigInt.one,
        gasPrice: BigInt.from(60000000),
      );
      final ok = await service.hasEnoughGasForRootstockTx(_kWalletAddress,
          estimatedGasLimit: 100000, httpClientOverride: client);
      expect(ok, isFalse);
    });

    test('fails open (returns true) when the RPC call errors', () async {
      final service = WalletServiceImpl();
      final failingClient = MockClient((request) async => http.Response('boom', 500));
      final ok = await service.hasEnoughGasForRootstockTx(_kWalletAddress,
          httpClientOverride: failingClient);
      expect(ok, isTrue);
    });
  });

  group('sendErc20Token', () {
    test('marks the transaction sent and records the network on success', () async {
      final service = WalletServiceImpl();
      final wallet = WalletEntity(
        amount: 0,
        btcAmount: 0,
        privateKey: _kPrivateKeyHex,
        walletName: 'test',
        walletId: '1',
        publicKey: _kWalletAddress,
        btcAddress: 'n2yGXrAPUg8YMg4cA5wSsi9MEkEAMqd1c1',
        ownerEmail: 'test@example.com',
        btcWif: 'cUjT4SDNUczT1NyjtL2bDKh6qemgjUaSmFcy1aMiLzZ8VZAs4kfU',
      );
      final client = _mockRpc();
      final tx = await service.sendErc20Token(
        wallet,
        _kTokenAddress,
        _kWalletAddress,
        BigInt.from(1000000000000000000),
        httpClientOverride: client,
      );
      expect(tx.transactionSent, isTrue);
      expect(tx.transactionId, isNotEmpty);
      expect(tx.network, Network.ROOTSTOCK_TESTNET.name);
    });

    test('marks the transaction not-sent when the node rejects it', () async {
      final service = WalletServiceImpl();
      final wallet = WalletEntity(
        amount: 0,
        btcAmount: 0,
        privateKey: _kPrivateKeyHex,
        walletName: 'test',
        walletId: '1',
        publicKey: _kWalletAddress,
        btcAddress: 'n2yGXrAPUg8YMg4cA5wSsi9MEkEAMqd1c1',
        ownerEmail: 'test@example.com',
        btcWif: 'cUjT4SDNUczT1NyjtL2bDKh6qemgjUaSmFcy1aMiLzZ8VZAs4kfU',
      );
      final client = _mockRpc(failSendRawTransaction: true);
      final tx = await service.sendErc20Token(
        wallet,
        _kTokenAddress,
        _kWalletAddress,
        BigInt.from(1000000000000000000),
        httpClientOverride: client,
      );
      expect(tx.transactionSent, isFalse);
    });
  });
}
