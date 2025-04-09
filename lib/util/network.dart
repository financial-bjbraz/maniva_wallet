enum Network {
  TESTNET(networkByte: 0x6f, name: 'Testnet'),
  MAINNET(networkByte: 0x00, name: 'Mainnet');

  const Network({
    required this.networkByte,
    required this.name,
  });

  final int networkByte;
  final String name;
}
