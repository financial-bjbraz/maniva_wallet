// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get title => 'Maniva Wallet';

  @override
  String get emailField => 'Digite seu e-mail';

  @override
  String get passwordField => 'Digite sua senha';

  @override
  String get login => 'Login';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get siginWithGoogle => 'Login com google';

  @override
  String get siginWithFb => 'Login com facebook';

  @override
  String get or => 'Ou';

  @override
  String get premios => 'Ganhe prêmios para cada indicação que abrir uma conta';

  @override
  String get refer => 'indicar amigos';

  @override
  String get recarga => 'Recarga celular';

  @override
  String get cobrar => 'Cobrar';

  @override
  String get depositar => 'Depositar';

  @override
  String get emprestimos => 'Emprestimo';

  @override
  String get transferir => 'Transferencias';

  @override
  String get limits => 'Limites';

  @override
  String get pagar => 'Pagar';

  @override
  String get bloquear => 'Bloquear';

  @override
  String get glogin => 'Logar com Google';

  @override
  String get alogin => 'Login Anônimo';

  @override
  String get anonimus => 'Anonimus';

  @override
  String get wallet => 'Wallet #';

  @override
  String get saldo => 'SALDO';

  @override
  String get saldoUltimoMes => 'Saldo Ultimo Mes';

  @override
  String get ultimaTransacao => 'Clique aqui para ver os detalhes das ultimas transacoes';

  @override
  String get copiar => 'Copiar palavras';

  @override
  String get mensagem_invalid_email => 'E-mail inválido';

  @override
  String get mensagem_invalid_password => 'Senha inválida. A senha deve ter no mínimo 8 caracteres';

  @override
  String get mensagem_user_exists => 'Usuário já existe';

  @override
  String get user_created_successfully => 'Usuário criado';

  @override
  String get mensagem_user_not_found => 'Usuário não encontrado';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Receber';

  @override
  String get sendTransaction => 'Enviar nova Transação';

  @override
  String get receiveTransactions => 'Seu endereço Rootstock';

  @override
  String get transactions => 'Transações';

  @override
  String get txSent => 'Nova transação enviada';

  @override
  String get txReceived => 'Nova transação recebida';

  @override
  String get amount => 'Digite o valor';

  @override
  String get destination => 'Endereço destino';

  @override
  String get copiedMessage => 'Copiado para área de transferência';

  @override
  String get configureAccount => 'Configurações';

  @override
  String get profile => 'Perfil';

  @override
  String get help => 'Ajuda';

  @override
  String get exit => 'Sair';

  @override
  String get exitWebMessage => 'Feche esta aba do navegador para sair';

  @override
  String get createNewWallet => 'Criar uma nova Carteira';

  @override
  String get restoreWallet => 'Restaurar uma carteira a partir de uma Frase de recuperação';

  @override
  String get restoreWalletWithPrivateKey => 'Restaurar uma carteira a partir de uma Chave Privada';

  @override
  String get share => 'Compartilhar';

  @override
  String get paste => 'Colar';

  @override
  String get accountOverviewTitle => 'Visão Geral da Conta';

  @override
  String get bitcoinLabel => 'Bitcoin';

  @override
  String get rootstockLabel => 'Rootstock';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get grandTotalLabel => 'Total geral';

  @override
  String get mainnetBannerConfigured => 'MAINNET — fundos reais, transações são irreversíveis';

  @override
  String get mainnetBannerNotConfigured =>
      'MAINNET selecionada mas não configurada — adicione ROOTSTOCK_NODE_MAIN / BITCOIN_NODE_MAIN / TOKENS_MAIN no .env';

  @override
  String get accountLabel => 'Conta';

  @override
  String get walletsLabel => 'Carteiras';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get networkLabel => 'Rede';

  @override
  String get aboutLabel => 'Sobre';

  @override
  String get appVersionLabel => 'Versão do app';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get systemDefaultLabel => 'Padrão do sistema';

  @override
  String get logOut => 'Sair da conta';

  @override
  String get switchToMainnetTitle => 'Mudar para Mainnet?';

  @override
  String get switchToMainnetBody =>
      'A Mainnet usa BTC/RBTC reais. As transações são irreversíveis — confira endereços e valores com atenção antes de enviar. Certifique-se de que os endpoints RPC da mainnet estão configurados antes de confiar nos saldos exibidos aqui.';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get switchToMainnetButton => 'Mudar para Mainnet';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String customNodeUrlsLabel(String network) {
    return 'URLs de nó personalizados ($network)';
  }

  @override
  String get customNodeUrlsHint =>
      'Substitua os endpoints padrão de nó/API para a rede atualmente selecionada. Deixe um campo vazio para usar o padrão do aplicativo.';

  @override
  String get bitcoinNodeUrlLabel => 'URL do nó RPC Bitcoin';

  @override
  String get bitcoinEsploraUrlLabel => 'URL da API Esplora Bitcoin';

  @override
  String get rootstockNodeUrlLabel => 'URL do nó RPC Rootstock';

  @override
  String get saveLabel => 'Salvar';

  @override
  String get resetToDefaultLabel => 'Restaurar padrão';

  @override
  String get nodeUrlSavedMessage => 'URL do nó salva';

  @override
  String get nodeUrlResetMessage => 'Revertido para a URL de nó padrão';

  @override
  String get invalidUrlMessage => 'Informe uma URL http(s) válida';

  @override
  String get noTransactionsYet => 'Nenhuma transação ainda';

  @override
  String get receivedLabel => 'Recebido';

  @override
  String get sentLabel => 'Enviado';

  @override
  String get atTheTimeLabel => 'Na época';

  @override
  String get nowLabel => 'Agora';

  @override
  String networkTransactionsTitle(String network) {
    return 'Transações — $network';
  }

  @override
  String get faq1Q => 'O que é Rootstock (RSK)?';

  @override
  String get faq1A =>
      'Rootstock é uma plataforma de contratos inteligentes protegida pela rede Bitcoin através de merge-mining. O RBTC, moeda usada para pagar transações na Rootstock, é lastreado 1:1 com o BTC.';

  @override
  String get faq2Q => 'Como envio fundos em Bitcoin ou Rootstock?';

  @override
  String get faq2A =>
      'Abra sua carteira, escolha a seção Bitcoin ou Rootstock, toque em Enviar e informe o endereço de destino e o valor. Você pode usar o botão Máximo para enviar todo o saldo menos a taxa de rede estimada.';

  @override
  String get faq3Q => 'Como funciona o vínculo BTC ↔ RBTC?';

  @override
  String get faq3A =>
      'O protocolo powpeg permite mover BTC para a Rootstock (peg-in) e de volta para o Bitcoin (peg-out). Suas contas Bitcoin e Rootstock são derivadas da mesma chave privada, por isso estão sempre disponíveis lado a lado nesta carteira.';

  @override
  String get faq4Q => 'Onde minhas chaves ficam armazenadas?';

  @override
  String get faq4A =>
      'Sua chave privada e frase de recuperação ficam armazenadas apenas neste dispositivo. Ninguém mais, nem mesmo os desenvolvedores do app, tem acesso a elas — anote sua frase de recuperação e guarde-a em segurança, pois ela não pode ser recuperada se for perdida.';

  @override
  String get faq5Q => 'Quais tokens são suportados na Rootstock?';

  @override
  String get faq5A =>
      'Além do RBTC, esta carteira mostra seus saldos dos tokens RIF, USDRIF, DOC, RIFPRO e tBRZ.';
}
