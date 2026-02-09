// lib/entities/bitcoin_address_details.dart

class BitcoinAddressDetails {
  final double balance; // BTC
  final int balanceSats; // sats
  final List<dynamic> txs; // raw tx objects or txids as returned by Blockbook
  final List<String> txids; // extracted txids
  final Map<String, dynamic> raw; // original response map

  BitcoinAddressDetails({
    required this.balance,
    required this.balanceSats,
    List<dynamic>? txs,
    List<String>? txids,
    Map<String, dynamic>? raw,
  })  : txs = txs ?? const [],
        txids = txids ?? const [],
        raw = raw ?? const {};

  factory BitcoinAddressDetails.fromMap(Map<String, dynamic> m) {
    final balance = m['balance'] is num ? (m['balance'] as num).toDouble() : double.tryParse('${m['balance']}') ?? 0.0;
    final balanceSats = m['balanceSats'] is int ? m['balanceSats'] as int : (m['balanceSats'] is num ? (m['balanceSats'] as num).toInt() : ((m['balance'] is num) ? ((m['balance'] as num) * 1e8).round() : 0));
    final txs = m['txs'] is List ? List<dynamic>.from(m['txs'] as List) : <dynamic>[];
    final txids = m['txids'] is List ? (m['txids'] as List).whereType<String>().toList() : <String>[];
    final raw = m['raw'] is Map<String, dynamic> ? Map<String, dynamic>.from(m['raw'] as Map) : Map<String, dynamic>.from(m);

    return BitcoinAddressDetails(balance: balance, balanceSats: balanceSats, txs: txs, txids: txids, raw: raw);
  }

  Map<String, dynamic> toMap() => {
        'balance': balance,
        'balanceSats': balanceSats,
        'txs': txs,
        'txids': txids,
        'raw': raw,
      };

  @override
  String toString() => 'BitcoinAddressDetails(balance: $balance, balanceSats: $balanceSats, txs: ${txs.length}, txids: ${txids.length})';
}
