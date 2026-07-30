# Plano: suporte funcional a Linux e Web

Status: proposta (não implementado). Verificação feita em 2026-07-30 a partir da `main` (commit `dc5b136`).

## Resumo executivo

CI já existe para as 4 plataformas (`android.yml`, `macos.yml`, `linux.yml`, `web.yml`), mas **todas as 4 estão falhando** no momento em `main`. A causa raiz não é a mesma em todos os casos:

1. **Bloqueio compartilhado (afeta as 4 plataformas)**: o step `flutter analyze .` falha com exit code 1 por causa de 3 issues nível `warning` pré-existentes (não são erros de compilação). `flutter analyze`/`dart analyze` retorna código de saída 1 sempre que há pelo menos um `warning`, independente de plataforma.
2. **Bloqueio específico do Android**: build do Android falha na configuração do Gradle — o plugin `flutter_windowmanager` (0.2.0, sem atividade desde ~2021) não declara `namespace` no `android/build.gradle`, o que o Android Gradle Plugin atual exige. Confirmado localmente (`flutter build apk --debug` falha com `Namespace not specified`).
3. **Bloqueio arquitetural real do Linux/Web**: mesmo depois de corrigir (1) e (2), o app **não vai funcionar de fato** em Linux/Web porque o armazenamento local (`sqflite_sqlcipher`, usado para carteira/transações/usuário) só declara implementação de plataforma para `android`/`ios`/`macos`. Não existe implementação `linux` nem `web`. Isso não impede o build (o Flutter simplesmente não registra a plugin para essas plataformas), mas qualquer chamada em runtime a `getDatabasesPath()`/`openDatabase()` (usadas em `lib/entities/entity_helper.dart:34-39`) lança `MissingPluginException` — ou seja, o app abre mas quebra ao tentar ler/gravar a carteira.
4. **Gap secundário**: `mobile_scanner` (leitor de QR) declara implementação para `android`/`ios`/`macos`/`web`, mas **não** para `linux`. `lib/pages/wallet/transactions/qr_scanner_page.dart` não tem nenhum gate de plataforma — em Linux, abrir essa tela vai lançar `MissingPluginException`.

Verificado localmente nesta sessão (macOS, sem host Linux disponível):
- `flutter build macos --debug` → sucesso.
- `flutter build web` → sucesso (com warnings de deprecação do `index.html` e um aviso de incompatibilidade wasm por causa de `universal_html`/`dart:html` — não bloqueia build normal, só build `--wasm`).
- `flutter build apk --debug` → **falha** (ver item 2 acima).
- `flutter build linux` → não pôde ser testado localmente (não é possível cross-compilar Linux desktop a partir de macOS); precisa ser validado via `workflow_dispatch` do `linux.yml` ou em uma máquina Linux real.

## Escopo do plano

### Fase 0 — Desbloquear CI (prioridade imediata, pequeno e isolado)

Isso desbloqueia as 4 pipelines ao mesmo tempo e não depende do resto do plano.

- **0.1** Corrigir os 3 warnings do analyzer:
  - `lib/services/wallet_service.dart:77` — `if (ownerEmail == null)` é morto (parâmetro é `String` não-nulável). Remover o check morto.
  - `lib/services/wallet_service.dart:222` — `rootstockNodeUrl!` com `!` redundante (receiver não pode ser nulo). Remover o `!`.
  - `test/wallet_service_rsk_test.dart:68` — `Map` sem argumento de tipo inferível. Anotar o tipo explicitamente.
- **0.2** Decidir a causa raiz do Android: patchear `flutter_windowmanager` (via override de `namespace` nos subprojects do `android/build.gradle` raiz — solução comum para plugins legados) OU substituí-lo por uma alternativa mantida (`no_screenshot`, `secure_application`, `screen_protector`) — dado que essa lib está abandonada há anos, e é usada para uma proteção de segurança real (bloquear screenshot de tela de seed/chave privada), a substituição é a opção mais robusta a médio prazo, mas o patch de namespace é o fix mais rápido para desbloquear o CI hoje.

Depois da Fase 0, esperado: `android.yml` e `macos.yml` verdes; `linux.yml` e `web.yml` compilam (job verde), mas o app ainda quebra em runtime ao tocar no banco de dados — ver Fase 1.

### Fase 1 — Armazenamento local em Linux e Web (bloqueador arquitetural principal)

O ponto central: `sqflite_sqlcipher` não existe para linux/web. Não dá para "instalar mais uma dependência" — é preciso decidir uma estratégia de storage por plataforma.

Opções a avaliar (a decidir antes de implementar, não durante):

- **Opção A — abstrair o banco atrás de uma interface e trocar a implementação por plataforma** (recomendado): manter `sqflite_sqlcipher` em Android/iOS/macOS (já funciona, já testado, sem regressão) e usar imports condicionais (`if (dart.library.io)` / `if (dart.library.html)`, ou um `DatabaseFactory` alternativo) para escolher a implementação em tempo de build:
  - **Linux**: `sqflite_common_ffi` (SQLite puro via FFI) + camada de criptografia própria no nível da aplicação (já que não é SQLCipher nativo), ou investigar bindings FFI de SQLCipher para Linux.
  - **Web**: não existe SQLite real no browser. Alternativas: `sqflite_common_ffi_web` (ainda experimental/instável), ou trocar o modelo de persistência para algo web-nativo como `sembast_web`/IndexedDB via `idb_shim`, reimplementando o schema atual (tabelas wallet/transaction/user/token) em um "document store".
  - Implica: `lib/entities/entity_helper.dart` precisa de um `DatabaseFactory` plugável, e o schema/queries em `wallet_helper.dart`, `transaction_helper.dart`, `user_helper.dart`, `token_helper.dart` precisam ser auditados para SQL específico de SQLCipher que não exista no engine substituto.
- **Opção B — aceitar armazenamento sem criptografia de banco em desktop/web**, confiando em outra camada (ex.: criptografar cada blob antes de gravar, independente do engine) — reduz esforço de migração de schema, mas muda o modelo de ameaça (decisão de produto/segurança, não só técnica) e precisa ser validada com quem é dono da decisão de segurança da wallet.
- **Opção C — não oferecer Linux/Web ainda**: publicar os artefatos de CI só como builds experimentais (`workflow_dispatch` manual, não gate de release) até a Opção A ou B ser resolvida.

**Este plano não escolhe entre A/B/C** — é a decisão que precisa de aprovação antes de qualquer código ser escrito.

### Fase 2 — Funcionalidades com suporte parcial de plugin

- **2.1 QR scanner em Linux**: `mobile_scanner` não suporta Linux. Adicionar gate de plataforma (`!Platform.isLinux` ou `defaultTargetPlatform`) em `qr_scanner_page.dart` e no botão que abre essa tela, escondendo a opção de câmera em Linux e mantendo apenas colar/digitar o endereço manualmente (já deve existir como alternativa — confirmar no fluxo de envio).
- **2.2 Revisão geral de plugins nativos usados no app** (`share_plus`, `url_launcher`, `package_info_plus`, `flutter_secure_storage` se vier a ser adicionado, `sentry_flutter`) — já têm implementação linux/web declarada (confirmado nesta sessão), não são bloqueadores, mas testar manualmente pelo menos uma vez por plataforma (share/link/versão) depois da Fase 0/1.
- **2.3 `SecureScreen`/`app_exit.dart`**: já corretamente no-op em Linux e Web (confirmado — nenhuma mudança necessária).

### Fase 3 — Validação

- **3.1** Rodar `linux.yml` via `workflow_dispatch` (ou abrir PR de teste) depois da Fase 0 para confirmar que o build Linux realmente compila em `ubuntu-latest` com as deps GTK já configuradas no workflow — não foi possível validar localmente nesta sessão (sem host Linux).
- **3.2** Depois da Fase 1, testar manualmente em uma VM/máquina Linux real e no Chrome (web): criar wallet, ver saldo, enviar transação mock — os três fluxos que tocam o banco local.
- **3.3** Adicionar ao `CLAUDE.md` do projeto uma seção equivalente à de Bitcoin/RSK explicando a divisão de storage por plataforma, para não ser reintroduzido incorretamente no futuro (mesmo padrão já usado para a separação Esplora/RPC do Bitcoin).

## O que este plano NÃO inclui

- Nenhuma alteração de código foi feita. Este documento é só o plano.
- Não decide entre as opções A/B/C da Fase 1 — isso precisa de uma decisão explícita antes da implementação.
- Não cobre Windows (fora do escopo pedido).

## Achados verificados nesta sessão (evidência)

- `flutter build macos --debug` → `✓ Built build/macos/Build/Products/Debug/maniva_wallet.app`
- `flutter build web` → `✓ Built build/web`
- `flutter build apk --debug` → falha: `Namespace not specified` em `flutter_windowmanager-0.2.0/android/build.gradle`
- `flutter analyze` local → exit code 1, 47 issues (3 `warning`, resto `info`) — mesmo resultado observado nos logs de CI (`gh run view 30506686040/30506686048 --log-failed`)
- `git log --oneline --branch main` via `gh run list` → últimos 4 runs em `main` (`Linux Build`, `macOS Build`, `Android`, `Web Build`) todos `failure`
- `sqflite_sqlcipher-3.4.0/pubspec.yaml` → `plugin.platforms` lista só `android`, `ios`, `macos`
- `mobile_scanner-6.0.11/pubspec.yaml` → `plugin.platforms` lista `android`, `ios`, `macos`, `web` (sem `linux`)
- `share_plus`, `url_launcher`, `package_info_plus` → todos com implementação `linux` e `web` declarada, sem gap
