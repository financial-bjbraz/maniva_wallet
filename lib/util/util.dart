import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

const databaseName = "my_rootstock_wallet.db";
const RBTC_DECIMAL_PLACES = 1000000000000000000;
const RBTC_DECIMAL_PLACES_COUNT = 18;

Color? orange() => const Color.fromRGBO(255, 145, 0, 1);
Color? pink() => const Color.fromRGBO(255, 112, 224, 1);
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
  final snackBar = SnackBar(
    content: Text(message),
    action: SnackBarAction(
      label: 'Ok',
      onPressed: () {},
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

final ButtonStyle orangeButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: orange(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle yellowButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: yellow(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle lightBlueButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: lightBlue(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle pinkButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: pink(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle greenButton = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: green(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle pinkButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(85, 36),
  backgroundColor: pink(),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

final ButtonStyle blackWhiteButton = ElevatedButton.styleFrom(
  minimumSize: const Size(90, 36),
  backgroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const StadiumBorder(),
  side: const BorderSide(
      width: 2,
      color: Colors.black
  ),
);

const whiteText = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 20,
    color: Colors.white);

const blackText = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 20,
    color: Colors.black);

const smallBlackText = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    color: Colors.black);

Future<void> delay(BuildContext context, int seconds) {
  return Future.delayed(Duration(seconds: seconds), () {});
}

verifyAndCreateDataBase() async {
  var created = await isTableCreated();

  openDataBase();

  if(!created) {
    createTable();
  }
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
  var created = prefs.getString("dataBaseCreated_4");
  return created != null;
}

Future<String> getIndex() async {
  var index = 0;
  final prefs = await SharedPreferences.getInstance();
  var indexStorage = prefs.getString("index");

  if(indexStorage != null) {
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
   await prefs.setString("dataBaseCreated", "true");
}

setLastUsdPrice(int price) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("lastBtcPrice", price.toString());
}

Future<int> getLastUsdPrice() async {
  final prefs = await SharedPreferences.getInstance();
  final String? valor = prefs.getString("lastBtcPrice");
  return int.parse(valor ?? "0");
}

Future<Database> openDataBase() async {
  if (kDebugMode) {
    print("====================================================================");
    print("==================== Opening database ==================");
  }

  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, databaseName);
  Database database = await openDatabase(path, version: 3,
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE wallets(privateKey TEXT PRIMARY KEY, walletName TEXT, walletId TEXT,publicKey TEXT, ownerEmail TEXT, amount REAL)',
          );
          if (kDebugMode) {
            print("creating table users ");
          }
          await db.execute(
            'CREATE TABLE users(name TEXT PRIMARY KEY, email TEXT, userId TEXT, password TEXT)',
          );
          await db.execute(
            'CREATE TABLE transactions(transactionId TEXT PRIMARY KEY, walletId TEXT, amountInWeis INTEGER, valueInUsdFormatted TEXT, valueinWeiFormatted TEXT, date TEXT, status TEXT, type INTEGER, destination TEXT)',
          );
          if (kDebugMode) {
            print("created table users ");
          }
        });
  try {
    database.transaction((txn) async {
      await txn.execute(
          "CREATE TABLE wallets(privateKey TEXT PRIMARY KEY, walletName TEXT, walletId TEXT,publicKey TEXT, ownerEmail TEXT, amount REAL);");
    });
    database.transaction((txn) async {
      await txn.execute(
          "CREATE TABLE users(name TEXT PRIMARY KEY, email TEXT, userId TEXT, password TEXT)");
    });
    database.transaction((txn) async {
      await txn.execute('CREATE TABLE transactions(transactionId TEXT PRIMARY KEY, walletId TEXT, amountInWeis INTEGER, valueInUsdFormatted TEXT, valueinWeiFormatted TEXT, date TEXT, status TEXT, type INTEGER, destination TEXT)');
    });
  } catch(e){
    if (kDebugMode) {
      print("Error occurred");
    }
  }

  if (kDebugMode) {
    print("====================================================================");
    print("==========Database opened  =============");
  }

  return database;
}


createTable() async {
  openDataBase();
}

String formatAddress(final String publicKey) {
  var address = publicKey;
  address = "${address.substring(0, 8)}...${address.substring(
      address.length - 8, address.length)}";
  return address;
}

String formatAddressWithParameter(final String publicKey, final int param) {
  var address = publicKey;
  address = "${address.substring(0, param)}...${address.substring(
      address.length - param, address.length)}";
  return address;
}

String formatAddressMinimal(final String publicKey) {
  var address = publicKey;
  address = "${address.substring(0, 4)}...${address.substring(
      address.length - 4, address.length)}";
  return address;
}

InputDecoration simmpleDecoration(final String labelText, final Icon icon) {
  return InputDecoration(
      focusColor: Colors.white,
      enabled: true,

      fillColor: Colors.white,
      prefixIcon: icon,
      labelText: labelText,
      labelStyle: const TextStyle( color: Colors.white ),
      enabledBorder: const OutlineInputBorder(
        borderSide:
        BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide:
        BorderSide(width: 2, color: Colors.white),
      ),
      border: const OutlineInputBorder(
        borderSide:
        BorderSide(width: 1, color: Colors.white),
      ),
      suffixIcon: IconButton(
        icon: const Icon(Icons.done, color: Colors.white,),
        splashColor: Colors.green,
        tooltip: "Submit",
        onPressed: () {

        },
      ));
}
