enum RbtcMultiple { wei, kwei, mwei, gwei, rbtc }

class Wei {
  late BigInt src;
  late String currency;
  final conversor = BigInt.from(1000000000000000000);

  Wei({required this.src, required this.currency});

  String toRBTCString() {
    var valueMul2 = src / conversor;
    return valueMul2.toStringAsFixed(18);
  }

  String toRBTCTrimmedString() {
    var valueMul = src / conversor;
    return valueMul.toStringAsFixed(2);
  }

  double getWei() {
    return src / conversor;
  }

  String toRBTCTrimmedStringPlaces(int places) {
    var valueMul = src / conversor;
    return valueMul.toStringAsFixed(places);
  }

  String toRBTCStringFixed2() {
    try {
      final amount = getWei(); // existing Wei method returning a double
      if (amount.isNaN || amount.isInfinite) return "0.00";
      return amount.toStringAsFixed(2);
    } catch (_) {
      return "0.00";
    }
  }

  String toRBTCStringFixed4() {
    try {
      final amount = getWei(); // existing Wei method returning a double
      if (amount.isNaN || amount.isInfinite) return "0.00";
      return amount.toStringAsFixed(4);
    } catch (_) {
      return "0.00";
    }
  }
}
