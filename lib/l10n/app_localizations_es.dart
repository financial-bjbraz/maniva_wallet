// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get title => 'Maniva Wallet';

  @override
  String get emailField => 'Rellena su correo';

  @override
  String get passwordField => 'Escriba su contraseña';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get siginWithGoogle => 'Iniciar sesión con Google';

  @override
  String get siginWithFb => 'Iniciar sesión con Facebook';

  @override
  String get or => 'O';

  @override
  String get premios => 'Gana recompensas por cada referido que abra una cuenta';

  @override
  String get refer => 'Referir amigos';

  @override
  String get recarga => 'Recargar celular';

  @override
  String get cobrar => 'Cobrar';

  @override
  String get depositar => 'Depositar';

  @override
  String get emprestimos => 'Prestar';

  @override
  String get transferir => 'Transferir';

  @override
  String get limits => 'Límites';

  @override
  String get pagar => 'Pagar';

  @override
  String get bloquear => 'Bloquear';

  @override
  String get glogin => 'Iniciar sesión con Google';

  @override
  String get alogin => 'Inicio de sesión anónimo';

  @override
  String get anonimus => 'Anónimo';

  @override
  String get wallet => 'Billetera #';

  @override
  String get saldo => 'SALDO';

  @override
  String get saldoUltimoMes => 'Saldo del mes pasado';

  @override
  String get ultimaTransacao => 'Haga clic aquí para ver los detalles de las últimas transacciones';

  @override
  String get copiar => 'Copiar al portapapeles';

  @override
  String get continuar => 'Continuar';

  @override
  String get mensagem_invalid_email => 'Correo inválido';

  @override
  String get mensagem_invalid_password => 'Contraseña inválida. Debe tener al menos 8 caracteres';

  @override
  String get mensagem_user_exists => 'El usuario ya existe';

  @override
  String get user_created_successfully => 'Usuario creado';

  @override
  String get mensagem_user_not_found => 'Usuario no encontrado';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Recibir';

  @override
  String get sendTransaction => 'Enviar';

  @override
  String get receiveTransactions => 'Su dirección Rootstock';

  @override
  String get transactions => 'Transacciones';

  @override
  String get txSent => 'Nueva transacción enviada';

  @override
  String get txReceived => 'Nueva transacción recibida';

  @override
  String get amount => 'Rellena el monto';

  @override
  String get destination => 'Dirección destino';

  @override
  String get copiedMessage => 'Copiado al portapapeles';

  @override
  String get configureAccount => 'Configuración';

  @override
  String get profile => 'Perfil';

  @override
  String get help => 'Ayuda';

  @override
  String get exit => 'Salir';

  @override
  String get exitWebMessage => 'Cierra esta pestaña del navegador para salir';

  @override
  String get createNewWallet => 'Crear una nueva billetera';

  @override
  String get restoreWallet => 'Restaurar billetera con frase de recuperación';

  @override
  String get restoreWalletWithPrivateKey => 'Restaurar billetera con clave privada';

  @override
  String get share => 'Compartir';

  @override
  String get paste => 'Pegar';

  @override
  String get accountOverviewTitle => 'Resumen de la cuenta';

  @override
  String get bitcoinLabel => 'Bitcoin';

  @override
  String get rootstockLabel => 'Rootstock';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get grandTotalLabel => 'Total general';

  @override
  String get mainnetBannerConfigured =>
      'MAINNET — fondos reales, las transacciones son irreversibles';

  @override
  String get mainnetBannerNotConfigured =>
      'MAINNET seleccionada pero no configurada — agregue ROOTSTOCK_NODE_MAIN / BITCOIN_NODE_MAIN / TOKENS_MAIN en el .env';

  @override
  String get accountLabel => 'Cuenta';

  @override
  String get walletsLabel => 'Billeteras';

  @override
  String get emailLabel => 'Correo';

  @override
  String get networkLabel => 'Red';

  @override
  String get aboutLabel => 'Acerca de';

  @override
  String get appVersionLabel => 'Versión de la app';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get systemDefaultLabel => 'Predeterminado del sistema';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get switchToMainnetTitle => '¿Cambiar a Mainnet?';

  @override
  String get switchToMainnetBody =>
      'Mainnet usa BTC/RBTC reales. Las transacciones son irreversibles — verifique direcciones y montos antes de enviar. Asegúrese de que los endpoints RPC de mainnet estén configurados antes de confiar en los saldos mostrados aquí.';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get switchToMainnetButton => 'Cambiar a Mainnet';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String customNodeUrlsLabel(String network) {
    return 'URLs de nodo personalizadas ($network)';
  }

  @override
  String get customNodeUrlsHint =>
      'Sobrescribe los endpoints de nodo/API predeterminados para la red seleccionada actualmente. Deja un campo vacío para usar el valor predeterminado de la app.';

  @override
  String get bitcoinNodeUrlLabel => 'URL del nodo RPC de Bitcoin';

  @override
  String get bitcoinEsploraUrlLabel => 'URL de la API Esplora de Bitcoin';

  @override
  String get rootstockNodeUrlLabel => 'URL del nodo RPC de Rootstock';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get resetToDefaultLabel => 'Restablecer valor predeterminado';

  @override
  String get nodeUrlSavedMessage => 'URL del nodo guardada';

  @override
  String get nodeUrlResetMessage => 'Se restableció la URL de nodo predeterminada';

  @override
  String get invalidUrlMessage => 'Ingresa una URL http(s) válida';

  @override
  String get saveNodeUrlsButton => 'Guardar configuración de nodo';

  @override
  String get nodeUrlsSavedMessage => 'Configuración de nodo guardada';

  @override
  String get noTransactionsYet => 'Aún no hay transacciones';

  @override
  String get receivedLabel => 'Recibido';

  @override
  String get sentLabel => 'Enviado';

  @override
  String get atTheTimeLabel => 'En su momento';

  @override
  String get nowLabel => 'Ahora';

  @override
  String networkTransactionsTitle(String network) {
    return 'Transacciones — $network';
  }

  @override
  String get faq1Q => '¿Qué es Rootstock (RSK)?';

  @override
  String get faq1A =>
      'Rootstock es una plataforma de contratos inteligentes asegurada por la red de Bitcoin mediante merge-mining. El RBTC, la moneda usada para pagar transacciones en Rootstock, está anclado 1:1 con el BTC.';

  @override
  String get faq2Q => '¿Cómo envío fondos en Bitcoin o Rootstock?';

  @override
  String get faq2A =>
      'Abra su billetera, elija la sección Bitcoin o Rootstock, toque Enviar e ingrese la dirección de destino y el monto. Puede usar el botón Máximo para enviar todo su saldo menos la tarifa de red estimada.';

  @override
  String get faq3Q => '¿Cómo funciona el anclaje BTC ↔ RBTC?';

  @override
  String get faq3A =>
      'El protocolo powpeg le permite mover BTC hacia Rootstock (peg-in) y de vuelta a Bitcoin (peg-out). Sus cuentas de Bitcoin y Rootstock se derivan de la misma clave privada, por lo que siempre están disponibles juntas en esta billetera.';

  @override
  String get faq4Q => '¿Dónde se guardan mis claves?';

  @override
  String get faq4A =>
      'Su clave privada y frase de recuperación se guardan únicamente en este dispositivo. Nadie más, ni siquiera los desarrolladores de la app, tiene acceso a ellas — anote su frase de recuperación y guárdela con cuidado, ya que no se puede recuperar si se pierde.';

  @override
  String get faq5Q => '¿Qué tokens son compatibles en Rootstock?';

  @override
  String get faq5A =>
      'Además del RBTC, esta billetera muestra sus saldos de los tokens RIF, USDRIF, DOC, RIFPRO y tBRZ.';

  @override
  String get walletSecurityTitle => 'Seguridad de la Billetera';

  @override
  String get walletSecurityWarning =>
      'Esta pantalla controla los fondos de esta billetera. Nunca comparta su clave privada o WIF con nadie, y asegúrese de que nadie esté mirando su pantalla.';

  @override
  String get privateKeyLabel => 'Clave Privada';

  @override
  String get bitcoinWifLabel => 'Clave Privada de Bitcoin (WIF)';

  @override
  String get revealLabel => 'Revelar';

  @override
  String get hideLabel => 'Ocultar';

  @override
  String get confirmSavedKeyLabel => 'He guardado mi clave privada de forma segura';

  @override
  String get deleteWalletButton => 'Eliminar Billetera';

  @override
  String get deleteWalletConfirmTitle => '¿Eliminar esta billetera?';

  @override
  String get deleteWalletConfirmBody =>
      'Esto elimina permanentemente la billetera de este dispositivo. Esta acción no se puede deshacer — asegúrese de haber guardado su clave privada, ya que es la única forma de acceder a estos fondos nuevamente.';

  @override
  String get deleteWalletConfirmButton => 'Eliminar';

  @override
  String get walletDeletedMessage => 'Billetera eliminada';
}
