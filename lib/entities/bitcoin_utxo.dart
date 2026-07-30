// dart
// lib/models/utxo.dart

class Utxo {
  final String txid;
  final int vout;
  final double amount; // BTC
  final String? scriptPubKey;
  final String? address;
  final int? confirmations;
  final bool? spendable;
  final DateTime? confirmedAt;
  bool selected = false;

  Utxo({
    required this.txid,
    required this.vout,
    required this.amount,
    this.scriptPubKey,
    this.address,
    this.confirmations,
    this.spendable,
    this.confirmedAt,
  });

  /// Create from a JSON/RPC map. Accepts `amount` as num or String.
  factory Utxo.fromMap(Map<String, dynamic> m) {
    final amtRaw = m['amount'];
    double amt = 0.0;
    if (amtRaw is num) {
      amt = amtRaw.toDouble();
    } else if (amtRaw is String) {
      amt = double.tryParse(amtRaw) ?? 0.0;
    }

    return Utxo(
      txid: m['txid'] as String,
      vout: (m['vout'] is int) ? m['vout'] as int : int.parse('${m['vout']}'),
      amount: amt,
      scriptPubKey: m['scriptPubKey'] as String?,
      address: m['address'] as String?,
      confirmations: m['confirmations'] is int
          ? m['confirmations'] as int
          : (m['confirmations'] != null ? int.tryParse('${m['confirmations']}') : null),
      spendable: m['spendable'] is bool ? m['spendable'] as bool : null,
      confirmedAt: m['confirmedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(m['confirmedAt'] as int)
          : null,
    );
  }

  /// Convert to a plain map (suitable for serialization).
  Map<String, dynamic> toMap() {
    return {
      'txid': txid,
      'vout': vout,
      'amount': amount,
      if (scriptPubKey != null) 'scriptPubKey': scriptPubKey,
      if (address != null) 'address': address,
      if (confirmations != null) 'confirmations': confirmations,
      if (spendable != null) 'spendable': spendable,
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.millisecondsSinceEpoch,
    };
  }

  /// Helper for RPC `createrawtransaction` inputs: `{ "txid": ..., "vout": ... }`
  Map<String, dynamic> toRpcInput() => {'txid': txid, 'vout': vout};

  Utxo copyWith({
    String? txid,
    int? vout,
    double? amount,
    String? scriptPubKey,
    String? address,
    int? confirmations,
    bool? spendable,
    DateTime? confirmedAt,
  }) {
    return Utxo(
      txid: txid ?? this.txid,
      vout: vout ?? this.vout,
      amount: amount ?? this.amount,
      scriptPubKey: scriptPubKey ?? this.scriptPubKey,
      address: address ?? this.address,
      confirmations: confirmations ?? this.confirmations,
      spendable: spendable ?? this.spendable,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  String toString() {
    return 'Utxo(txid: $txid, vout: $vout, amount: $amount, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Utxo &&
        other.txid == txid &&
        other.vout == vout &&
        other.amount == amount &&
        other.address == address;
  }

  @override
  int get hashCode => Object.hash(txid, vout, amount, address);
}
