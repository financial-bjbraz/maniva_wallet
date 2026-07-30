# myRootstockWallet (maniva_wallet) — Guia para Claude Code

Wallet Flutter (iOS, Android, macOS, Linux, web) que suporta Bitcoin (BTC, testnet3) e Rootstock (RSK/RBTC + tokens ERC20 como RIF, USDRIF, DOC, RIFPRO, tBRZ).

**Não confundir com os projetos da plataforma BRLN** (cripto-controller, cripto-dashboard, cripto-bff, dfns_integration) descritos em instruções globais — este é um projeto separado e sem relação.

---

## Arquitetura da wallet

Uma única chave privada (`WalletEntity.privateKey`) gera tanto o endereço/WIF Bitcoin (`getBtcAddressFromPrivateKey`/`getBtcWifFromPrivateKey` em `lib/services/wallet_service.dart`) quanto o endereço RSK/EVM, guardados juntos na mesma linha da wallet. Isso é proposital: permite que a mesma conta opere nas duas chains, o que importa para o bridge PowPeg da Rootstock (BTC↔RBTC), já que o PowPeg depende do mesmo par de chaves produzindo endereços consistentes nas duas redes.

**Arquivos-chave**:
- `lib/services/bitcoin_service.dart` — `BitcoinNodeClient`: toda a lógica de RPC Bitcoin Core + REST Esplora (UTXOs, fees, montagem de tx, assinatura offline via `dartsv`).
- `lib/services/wallet_service.dart` — `WalletServiceImpl`: orquestra os fluxos BTC e RSK (web3dart); mantém `CreateTransactionServiceImpl service` para persistir histórico de transações.
- `lib/pages/wallet/transactions/bitcoin_account_send.dart` — tela de envio de BTC.
- `lib/entities/transaction_helper.dart` — modelo `SimpleTransaction` + persistência sqlite.
- `test/bitcoin_transfer_test.dart` — arquivo grande com testes unitários (mockados) e testes de integração (rede real) para os fluxos Bitcoin.

---

## Backend Bitcoin — por que é dividido em duas fontes

`BitcoinNodeClient` divide as chamadas Bitcoin propositalmente — não simplificar de volta para uma única fonte:

- **Descoberta de UTXO + saldo**: `fetchUtxosFromEsplora` / `fetchBalanceFromEsplora`, usando uma API REST compatível com Esplora (env var `BITCOIN_ESPLORA_URL`, default `https://mempool.space/testnet/api`).
- **Apenas estimativa de fee + broadcast**: o nó Bitcoin Core via JSON-RPC (env var `BITCOIN_NODE`, ex. `bitcoin-testnet-rpc.publicnode.com`) — *somente* para `estimatesmartfee` e `sendrawtransaction`.
- **Assinatura**: sempre offline, no cliente, usando a WIF da própria wallet via `dartsv` — nunca via RPC do nó.

**Motivo**: provedores públicos de RPC Bitcoin (única opção realista para uma wallet mobile sem operar o próprio nó) rejeitam métodos RPC que exigem wallet carregada no servidor (`listunspent`, `getrawchangeaddress`, `scantxoutset`, `signrawtransactionwithwallet`, `sendtoaddress`) com `-32701 Method not allowed` — confirmado empiricamente contra `bitcoin-testnet-rpc.publicnode.com`. O código original assumia um nó self-hosted com wallet carregada, o que não existe neste deployment; essa incompatibilidade era a causa raiz do envio/saldo de Bitcoin estarem completamente quebrados (corrigido em 2026-07-27).

**Como aplicar**: se o envio/saldo de BTC quebrar novamente, verificar se essa separação não foi reintroduzida incorretamente — não rotear saldo/UTXO de volta por `getBalanceForAddress`/`listUtxos` (RPC) como caminho primário; eles existem apenas como fallback best-effort para quem roda nó próprio. Além disso: `changeAddress` em `sendTransferUsingUtxos` é parâmetro obrigatório (o próprio endereço da wallet) — não há fallback via `getrawchangeaddress` de propósito.

### Pegadinha do `dartsv`

Ao estender a assinatura offline além de P2PKH (ex. adicionar suporte a P2WPKH/segwit), atenção: o `UnlockingScriptBuilder` padrão do `dartsv` em um `TransactionInput` **não** monta corretamente o scriptSig a partir de uma assinatura adicionada — ele apenas ecoa de volta o último script que viu (inclusive o subscript temporário usado no cálculo do sighash), produzindo uma transação inválida que não gera exceção localmente, mas é rejeitada pela rede como `mempool-script-verify-flag-failed`. É necessário anexar explicitamente o `*UnlockBuilder` correto (ex. `P2PKHUnlockBuilder`) ao input **antes** de chamar `TransactionSigner.sign()`. Isso já está tratado para P2PKH em `_signRawTransactionOffline`; só é relevante ao adicionar novos tipos de script.

---

## Armazenamento local — por que é dividido por plataforma

`lib/entities/entity_helper.dart` (`EntityHelper._initDatabase`) escolhe o `DatabaseFactory` em runtime por plataforma — não simplificar de volta para um único `sqflite_sqlcipher.openDatabase(...)` incondicional:

- **Android/iOS/macOS**: `sqflite_sqlcipher` — banco criptografado com a `PRIVATE_KEY` do `.env` como senha (comportamento original, inalterado).
- **Linux**: `sqflite_common_ffi` (`databaseFactoryFfi`), com o arquivo do banco em `getApplicationSupportDirectory()` (via `path_provider`) em vez de `getDatabasesPath()` (conceito Android-específico que não existe em desktop).
- **Web**: `sqflite_common_ffi_web` (`databaseFactoryFfiWeb`), que persiste em IndexedDB via um shared worker. Precisa de `web/sqlite3.wasm` e `web/sqflite_sw.js` no repo (compilado de `web/sqflite_sw.dart` com `dart compile js`, já que a ferramenta oficial `dart run sqflite_common_ffi_web:setup` depende do `webdev`/`build_runner`, que falhou neste ambiente com "Unable to start build daemon" — se precisar regenerar após atualizar a versão do pacote, tentar o `setup` oficial primeiro e cair para `dart compile js -o web/sqflite_sw.js web/sqflite_sw.dart` se ele falhar de novo).

**Motivo**: `sqflite_sqlcipher` só declara implementação de plataforma para `android`/`ios`/`macos` (confirmado no `pubspec.yaml` do pacote) — não existe para `linux` nem `web`. Sem essa divisão, `getDatabasesPath()`/`openDatabase()` lançam `MissingPluginException` em runtime nessas duas plataformas assim que a wallet tenta ler/gravar qualquer dado (carteiras, transações, usuário, tokens).

**Tradeoff de segurança conhecido, não descuido**: em Linux e Web o banco **não é criptografado em repouso** — não existe hoje um pacote maduro equivalente ao SQLCipher para essas duas plataformas (a rota "correta" seria `sqlite3` + build "SQLite3MultipleCiphers", mas isso depende de build hooks de native assets ainda experimentais no Flutter e de um asset wasm de cipher à parte — ver `docs/linux-web-support-plan.md` para os detalhes e a decisão explícita de adiar isso). Isso significa que a chave privada da wallet fica em texto plano no arquivo sqlite local (Linux) ou no IndexedDB do navegador (Web) nessas duas plataformas. Se isso mudar de tradeoff aceitável para bloqueador, essa é a única linha de código que precisa mudar (`EntityHelper._initDatabase`), já que o resto do DAO (`wallet_helper.dart`, `transaction_helper.dart`, `user_helper.dart`, `token_helper.dart`) só depende da interface comum `sqflite_common`'s `Database`, não do `sqflite_sqlcipher` diretamente.

O `mobile_scanner` (QR) também não tem implementação Linux (Android/iOS/macOS/Web sim) — o botão "Scan" em `bitcoin_account_send.dart`/`account_send.dart` é desabilitado (`onPressed: null`) nessa plataforma via `isQrScannerSupported` (`qr_scanner_page.dart`), mantendo colar/digitar o endereço manualmente como única opção lá.

---

## Testes — cuidado com rede real

O grupo `'Integração – transferência real testnet3'` vive em `test/integration/bitcoin_transfer_integration_test.dart` e **agora é bloqueado por `@Tags(['integration'])`** no topo do arquivo — `flutter test` (sem argumentos) pula esse grupo automaticamente; só roda com `flutter test --tags integration`. (Antes ficava em `test/bitcoin_transfer_test.dart` sem gating real, apenas documentado em comentário — corrigido em algum commit antes de 2026-07-29, confirmado ao rodar a suíte completa e ver `Skip: Hits live testnet3 network...`.) Quando executado deliberadamente com a tag, o teste deriva um endereço da `PRIVATE_KEY` do `.env`, busca UTXOs reais via Esplora e faz broadcast de uma transação real de 1000 sats na testnet3 (pula graciosamente via `markTestSkipped` se não houver saldo).

Isso é proposital (chave é testnet-only, fundos sem valor), mas significa que: o saldo de teste diminui a cada execução com `--tags integration`, a suíte depende de serviços externos reais (mempool.space, nó RPC público), e é o único teste que exercita assinatura+broadcast reais de ponta a ponta — foi o que revelou o bug do `dartsv` acima, que todos os testes mockados não pegavam. Se o saldo acabar, reabastecer via https://coinfaucet.eu/en/btc-testnet/ no endereço derivado da `PRIVATE_KEY` atual do `.env` (impresso pelo próprio teste).

---

## Workflow preferido

Para investigações de bugs não-triviais neste projeto, o usuário prefere um fluxo em etapas: **revisão** (com evidência concreta, ex. testar diretamente os serviços externos envolvidos antes de escrever qualquer código) → **plano** → **ação**. Assim que o usuário der um sinal verde com direção concreta, pode seguir direto pelo plano e implementação sem reconfirmar cada passo.
