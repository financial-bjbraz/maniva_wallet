import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/home_page.dart';
import 'package:provider/provider.dart';

import '../entities/user_helper.dart';
import '../entities/wallet_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/create_user_service.dart';
import '../services/wallet_service.dart';
import '../util/util.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    verifyAndCreateDataBase();
    return const Scaffold(
      backgroundColor: Color.fromRGBO(0, 0, 0, 0),
      body: Body(),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  void initState() {
    super.initState();
  }

  TextEditingController passwordController = TextEditingController();
  TextEditingController mailController = TextEditingController();
  late String mensagemInvalidEmail = AppLocalizations.of(context)!.mensagem_invalid_email;
  late String mensagemInvalidPassword = AppLocalizations.of(context)!.mensagem_invalid_password;
  late String mensagemUserExists = AppLocalizations.of(context)!.mensagem_user_exists;
  late String mensagemUserNotFound = AppLocalizations.of(context)!.mensagem_user_not_found;
  late String userCreatedSuccessfully = AppLocalizations.of(context)!.user_created_successfully;

  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context, listen: false);

  Widget loginButton() {
    final String loginAnonimousText = AppLocalizations.of(context)!.alogin;
    final String login = AppLocalizations.of(context)!.login;
    final String createAccount = AppLocalizations.of(context)!.createAccount;
    FocusNode textSecondFocusNode = FocusNode();

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(33.0),
              child: Image.asset('assets/images/maniva.png', height: 30),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        controller: mailController,
                        decoration: simmpleDecoration(
                            AppLocalizations.of(context)!.emailField,
                            const Icon(
                              Icons.person,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        focusNode: textSecondFocusNode,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        obscureText: true,
                        controller: passwordController,
                        decoration: simmpleDecoration(
                            AppLocalizations.of(context)!.passwordField,
                            const Icon(
                              Icons.password,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            var user = SimpleUser(
                                name: mailController.text,
                                email: mailController.text,
                                password: passwordController.text);
                            bool isValid = await validate(user, context);
                            if (isValid) {
                              goToHome(user);
                            }
                          },
                          style: pinkButton,
                          child: Row(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.create,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    login,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            var user = SimpleUser(
                                name: mailController.text,
                                email: mailController.text,
                                password: passwordController.text);

                            bool isValid = await validateCreateAccount(user, context);

                            if (isValid) {
                              goToHome(user);
                            }
                          },
                          style: greenButton,
                          child: Row(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    createAccount,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ]),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  const Text.rich(
                    TextSpan(
                      text: "Or ",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: clickLoginAnonimous,
                    style: lightBlueButton,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/anonimous.png",
                              color: Colors.white,
                              height: 30,
                              width: 70,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                loginAnonimousText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void clickLoginAnonimous() async {
    final anonimousUser = SimpleUser(
      name: AppLocalizations.of(context)!.anonimus,
      email:
          "${AppLocalizations.of(context)!.passwordField}@${AppLocalizations.of(context)!.passwordField}.com",
      password: "",
    );
    goToHome(anonimousUser);
  }

  void goToHome(SimpleUser user) async {
    final List<WalletEntity> wallets = await walletService.getWallets(user.email);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          wallets: wallets,
          user: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: loginButton(),
    );
  }

  Future<bool> validate(SimpleUser user, BuildContext context) async {
    final CreateUserServiceImpl createUserServiceImpl =
        Provider.of<CreateUserServiceImpl>(context, listen: false);

    var email = user.email;
    var password = user.password;

    if (email.isEmpty) {
      showMessage(mensagemInvalidEmail);
      return false;
    }

    if (password.isEmpty || password.length < 8) {
      showMessage(mensagemInvalidPassword);
      return false;
    }

    var userExists = await createUserServiceImpl.getUser(user);

    if (userExists == null) {
      showMessage(mensagemUserNotFound);
      return false;
    }

    return true;
  }

  Future<bool> validateCreateAccount(SimpleUser user, BuildContext context) async {
    final CreateUserServiceImpl createUserServiceImpl =
        Provider.of<CreateUserServiceImpl>(context, listen: false);

    var email = mailController.text;
    var password = passwordController.text;

    if (email.isEmpty) {
      showMessage(mensagemInvalidEmail);
      return false;
    }

    if (password.isEmpty || password.length < 8) {
      showMessage(mensagemInvalidPassword);
      return false;
    }
    var userExists = await createUserServiceImpl.getUser(user);
    if (userExists != null) {
      showMessage(mensagemUserExists);
    } else {
      createUserServiceImpl.createUser(user);
      showMessage(userCreatedSuccessfully);
    }
    return true;
  }

  void showMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
