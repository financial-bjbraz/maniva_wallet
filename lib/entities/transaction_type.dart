enum TransactionType {
  NONE(type: 0),
  REGULAR_OUTGOING(type: 1),
  REGULAR_INCOMING(type: 2),
  CONTRACT_DEPLOYMENT(type: 3),
  CONTRACT_EXECUTION(type: 4);

  const TransactionType({
    required this.type,
  });

  final int type;
}