

class SimpleTransaction {
  late String transactionId;
  late int amountInWeis;
  late String valueInUsdFormatted;
  late String valueInWeiFormatted;
  late bool? transactionSent;
  String date = '';
  int type = 0; // TransactionType
  final String walletId;
  final String? status;
  final String? destination;

  SimpleTransaction( {this.status,required this.transactionId, required this.amountInWeis, required this.date,
    required this.walletId, required this.valueInUsdFormatted, required this.valueInWeiFormatted, required this.type, required this.destination});

  Map<String, Object?> toMap() {
    return {
      'transactionId': transactionId,
      'amountInWeis': amountInWeis,
      'date': date,
      'walletId': walletId,
      'valueInUsdFormatted': valueInUsdFormatted,
      'valueInWeiFormatted': valueInWeiFormatted,
      'status': status,
      'type': type,
      'destination': destination
    };
  }

  @override
  String toString() {
    return 'SimpleTransaction{transactionId: $transactionId, amountInWeis: $amountInWeis, date: $date,  walletId: $walletId}, valueInUsdFormatted: ${valueInUsdFormatted}, valueInWeiFormatted: ${valueInWeiFormatted},  status: ${status} type: $type destination: $destination';
  }

}
