import 'dart:async';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../entities/entity_helper.dart';
import 'addresses.dart';
import 'network.dart';

const DATA_BASE_NAME = "rwallet.db";
const DATA_BASE_VERSION = 17;

const RBTC_DECIMAL_PLACES = 1000000000000000000;
const RBTC_DECIMAL_PLACES_COUNT = 18;
const SIMPLE_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";

Color? orange() => const Color.fromRGBO(255, 145, 0, 1);

Color pink() => const Color.fromRGBO(255, 112, 224, 1);

Color? green() => const Color.fromRGBO(121, 198, 0, 1);

Color? lightBlue() => const Color.fromRGBO(8, 255, 208, 1);

Color? purple() => const Color.fromRGBO(158, 118, 255, 1);

Color? yellow() => const Color.fromRGBO(222, 255, 26, 1);

const shimmerGradient = LinearGradient(
  colors: [
    Color(0xFFEBEBF4),
    Color(0xFFF4F4F4),
    Color(0xFFEBEBF4),
  ],
  stops: [
    0.1,
    0.3,
    0.4,
  ],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.clamp,
);

void showMessage(String message, BuildContext context) {
  // Clear any snackbar already showing/queued first — otherwise repeated
  // taps (e.g. tapping "Copy" a few times) queue up one snackbar per tap,
  // each waiting its turn, which reads as "the message never goes away".
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

/// Same as [raisedButtonStyle] but flat (no elevation) — used by menu/reward
/// buttons that sit on already-decorated containers.
final ButtonStyle raisedButtonStyleFlat = ElevatedButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  elevation: 0,
);

final ButtonStyle orangeButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: orange(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle yellowButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: yellow(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle lightBlueButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: lightBlue(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle pinkButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: pink(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle greenButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: green(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle purpleButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: purple(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle pinkButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: pink(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

final ButtonStyle blackWhiteButton = ElevatedButton.styleFrom(
  minimumSize: const Size(90, 36),
  backgroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
);

const whiteText = TextStyle(fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white);

const blackText = TextStyle(fontWeight: FontWeight.normal, fontSize: 20, color: Colors.black);

const smallBlackText = TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black);

/// Matches the bold-white label style used on the login page's pill buttons
/// (pinkButton/greenButton/lightBlueButton), sized for smaller inline buttons.
const smallWhiteBoldText =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white);

/// Shared style for helper/caption text under a field or amount (e.g. "USD
/// 0.00" previews, "Paste or Scan" hints).
const mutedCaptionText = TextStyle(color: Colors.grey, fontSize: 13);

Future<void> delay(BuildContext context, int seconds) {
  return Future.delayed(Duration(seconds: seconds), () {});
}

Future<bool> verifyAndCreateDataBase() async {
  var created = await isTableCreated();
  if (!created) {
    createTable();
  }
  return created;
}

TextSpan addressText(String address) {
  return TextSpan(
      text: address,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ));
}

EdgeInsets createPaddingBetweenRows() {
  return const EdgeInsets.only(left: 2, top: 5, bottom: 5, right: 2);
}

EdgeInsets createPaddingBetweenDifferentRows() {
  return const EdgeInsets.only(left: 2, top: 45, bottom: 5, right: 2);
}

Future<bool> isTableCreated() async {
  final prefs = await SharedPreferences.getInstance();
  var created = prefs.getString("dataBaseCreated$DATA_BASE_VERSION");
  return created != null;
}

Future<String> getIndex() async {
  var index = 0;
  final prefs = await SharedPreferences.getInstance();
  var indexStorage = prefs.getString("index");

  if (indexStorage != null) {
    index = int.parse(indexStorage);
    indexStorage = (index + 1).toString();
  } else {
    indexStorage = "0";
  }

  await prefs.setString("index", indexStorage);

  return index.toString();
}

setDataBaseCreated() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("dataBaseCreated$DATA_BASE_VERSION", "true");
}

setLastUsdPrice(int price) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("lastBtcPrice", price.toString());
  setLastUsdPriceTime();
}

String formatBalance(String balance) {
  if (balance == "0" || balance == "0.0") {
    return "0.0000";
  }
  return balance;
}

String formatUsd(String balanceInUsd) {
  try {
    double value = double.parse(balanceInUsd);
    return value.toStringAsFixed(2);
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
  return balanceInUsd;
}

setLastUsdPriceTime() async {
  DateFormat df = DateFormat(SIMPLE_DATE_FORMAT);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("lastBtcTime", df.format(DateTime.now()));
}

Future<DateTime> getLastUsdPriceTime() async {
  DateFormat df = DateFormat(SIMPLE_DATE_FORMAT);
  final prefs = await SharedPreferences.getInstance();
  final String valor = prefs.getString("lastBtcTime") ?? "2025-04-01 00:00:00";
  DateTime data = df.parse(valor, false);
  return data;
}

Future<int> getLastUsdPrice() async {
  final prefs = await SharedPreferences.getInstance();
  final String? valor = prefs.getString("lastBtcPrice");
  return int.parse(valor ?? "0");
}

openDataBase() async {
  await EntityHelper().setUp();
}

/// Persisted manual position/size of the wallet card on the home screen,
/// as fractions of screen height, so a user's manual drag/resize survives
/// app restarts.
Future<double?> getWalletCardTopFraction() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble("walletCardTopFraction");
}

Future<void> setWalletCardTopFraction(double fraction) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble("walletCardTopFraction", fraction);
}

Future<double?> getWalletCardHeightFraction() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble("walletCardHeightFraction");
}

Future<void> setWalletCardHeightFraction(double fraction) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble("walletCardHeightFraction", fraction);
}

/// Persisted testnet/mainnet toggle. Defaults to testnet (false) so a fresh
/// install never accidentally starts pointed at mainnet.
Future<bool> getIsMainnet() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("isMainnet") ?? false;
}

Future<void> setIsMainnet(bool isMainnet) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("isMainnet", isMainnet);
}

/// Persisted language override (an ISO 639-1 code like "en"/"pt"/"es"). Null
/// means "follow the system language" — the default, since there's no stored
/// value until the user explicitly picks one in Settings.
Future<String?> getLanguageCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("languageCode");
}

Future<void> setLanguageCode(String? languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  if (languageCode == null) {
    await prefs.remove("languageCode");
  } else {
    await prefs.setString("languageCode", languageCode);
  }
}

/// Persisted per-network custom node/API URL overrides (Settings > custom
/// node URLs). [key] is one of the constants below — kept separate per
/// testnet/mainnet so switching network mode can never silently point at the
/// wrong network's node. Null/absent means "use the .env default".
const String customBitcoinNodeUrlTestnetKey = "customBitcoinNodeUrlTestnet";
const String customBitcoinNodeUrlMainnetKey = "customBitcoinNodeUrlMainnet";
const String customBitcoinEsploraUrlTestnetKey = "customBitcoinEsploraUrlTestnet";
const String customBitcoinEsploraUrlMainnetKey = "customBitcoinEsploraUrlMainnet";
const String customRootstockNodeUrlTestnetKey = "customRootstockNodeUrlTestnet";
const String customRootstockNodeUrlMainnetKey = "customRootstockNodeUrlMainnet";

Future<String?> getCustomNodeUrl(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(key);
  return (value == null || value.trim().isEmpty) ? null : value.trim();
}

Future<void> setCustomNodeUrlPref(String key, String? value) async {
  final prefs = await SharedPreferences.getInstance();
  if (value == null || value.trim().isEmpty) {
    await prefs.remove(key);
  } else {
    await prefs.setString(key, value.trim());
  }
}

testEncriptData() {
  if (kDebugMode) {
    print("Teste de encriptacao");
  }
  const plainText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';
  if (kDebugMode) {
    print("PlainText:$plainText");
  }
  var encriptedText = encrypt(plainText);
  if (kDebugMode) {
    print("Encripted:$encriptedText");
  }
  var decryptedText = decrypt(encriptedText);
  if (kDebugMode) {
    print("Decripted$decryptedText");
  }
}

enc.Encrypter generateEncrypter() {
  final key = enc.Key.fromUtf8(getPlainKey());
  return enc.Encrypter(enc.AES(key));
}

String encrypt(String plainText) {
  final encrypter = generateEncrypter();
  final encrypted = encrypter.encrypt(plainText, iv: enc.IV.fromUtf8("baseutf8"));
  return encrypted.base16;
}

String decrypt(String encryptedText) {
  final encrypter = generateEncrypter();
  return encrypter.decrypt16(encryptedText, iv: enc.IV.fromUtf8("baseutf8"));
}

createTable() async {
  openDataBase();
}

String getPlainKey() {
  var plainKey = dotenv.env['PLAIN_KEY'];
  return plainKey ?? "";
}

String formatAddress(final String publicKey) {
  var address = toChecksumAddress(publicKey, Network.ROOTSTOCK_TESTNET.networkId);

  address = "${address.substring(0, 8)}...${address.substring(address.length - 8, address.length)}";
  return address;
}

String formatAddressWithParameter(final String publicKey, final int param) {
  var address = toChecksumAddress(publicKey, Network.ROOTSTOCK_TESTNET.networkId);
  address =
      "${address.substring(0, param)}...${address.substring(address.length - param, address.length)}";
  return address;
}

String formatTextWithParameter(final String text, final int param) {
  return "${text.substring(0, param)}...${text.substring(text.length - param, text.length)}";
}

String formatAddressMinimal(final String publicKey) {
  var address = toChecksumAddress(publicKey, Network.ROOTSTOCK_TESTNET.networkId);
  address = "${address.substring(0, 4)}...${address.substring(address.length - 4, address.length)}";
  return address;
}

InputDecoration simmpleDecoration(final String labelText, final Icon icon) {
  return InputDecoration(
      focusColor: Colors.white,
      enabled: true,
      fillColor: Colors.white,
      prefixIcon: icon,
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(width: 2, color: Colors.white),
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.white),
      ),
      suffixIcon: IconButton(
        icon: const Icon(
          Icons.done,
          color: Colors.white,
        ),
        splashColor: Colors.green,
        tooltip: "Submit",
        onPressed: () {},
      ));
}

loadWalletDataExample(String myAddress, String contractAddress, String privateKey) async {
  final node = dotenv.env['ROOTSTOCK_NODE'];
  final client = web3.Web3Client(node!, http.Client());
  // final credentials = web3.EthPrivateKey.fromHex(privateKey);

  final web3.EthereumAddress contractAddr = web3.EthereumAddress.fromHex(contractAddress);
  final web3.EthereumAddress receiver = web3.EthereumAddress.fromHex(myAddress);

  final abiCode = await rootBundle.loadString('assets/contracts/MetaCoin.abi');
  final contract =
      web3.DeployedContract(web3.ContractAbi.fromJson(abiCode, 'MetaCoin'), contractAddr);

  final balanceFunction = contract.function('getBalance');

  final balance =
      await client.call(contract: contract, function: balanceFunction, params: [receiver]);
  balance.first.toString();
}
