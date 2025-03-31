enum TransactionType {
  NONE(type: 0),
  REGULAR(type: 1),
  CONTRACT_DEPLOYMENT(type: 2),
  CONTRACT_EXECUTION(type: 3);

  const TransactionType({
    required this.type,
  });

  final int type;
}