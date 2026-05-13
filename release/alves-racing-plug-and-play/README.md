# Alves Racing - pacote plug-and-play

Pacote para testar o sistema de corridas em outro servidor **Qbox/FiveM**.

## O que vai no pacote

```txt
INSTALL.sql
server.cfg.example
resources/[alves]/alves-racing-core
resources/[alves]/alves-racingapp
```

## Requisitos no servidor do seu colega

Obrigatórios:

- `qbx_core`
- `ox_lib`
- `oxmysql`
- banco MySQL/MariaDB configurado no servidor

Opcional:

- `qbx_customs` — só para os comandos `/tuning`, `/bennys`, `/custom`, `/customizar`.

> Importante: isso é plug-and-play para **Qbox**. Não é standalone puro sem framework.

## Instalação

1. Copie a pasta `resources/[alves]` para a pasta `resources` do servidor.

2. Execute o arquivo `INSTALL.sql` no banco do servidor.

   Ele cria/prepara:

   - `race_tracks`
   - `racer_names`
   - `track_times`
   - `alves_vehicle_presets`

   Também adiciona uma pista demo: **Alves Demo - LSIA Sprint**.

3. Adicione no `server.cfg`, respeitando a ordem:

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core

# Opcional, apenas para tuning visual
# ensure qbx_customs

setr alves:themePrimary "#8b5cf6"
setr alves:themeBackground "#080712"

ensure alves-racing-core
ensure alves-racingapp
```

4. Reinicie o servidor ou rode no console:

```txt
refresh
ensure alves-racing-core
ensure alves-racingapp
```

## Como testar

- `F1` ou `/race` abre o tablet de corrida.
- Clique em Casual ou Ranked para entrar no lobby.
- Vote no mapa/carro e aguarde a contagem.
- `F2` abre/fecha lobby minimizado.
- `F3` sai do lobby.
- `/sair` sai da corrida.
- `/salvarpreset` salva o visual atual do veículo.

## Carros do pacote

Nesta versão de envio, a lista de carros foi trocada para veículos vanilla do GTA/FiveM para funcionar em servidor sem pacote JFx.

Se o servidor tiver carros custom, edite:

```txt
resources/[alves]/alves-racingapp/server/main.lua
```

E substitua a lista `QuickRaceVehicles` pelos spawn names reais.

## Recursos principais

- Lobby casual/ranked com votação de pista e veículo.
- ELO por tiers.
- Histórico/scoreboard de corridas.
- Preset visual por jogador/veículo.
- Phase/ghost durante corrida: competidores não colidem entre si.
- Players imortais, sem ragdoll/ejeção, combustível fixo 100.
- Performance máxima aplicada nos veículos.
- HUD/tablet com tema roxo configurável por convar.

## Observações

- O banco precisa ter pelo menos uma pista. O `INSTALL.sql` já cria uma pista demo.
- Para produção, substitua a pista demo pelas pistas reais do servidor.
- Se `qbx_customs` não estiver instalado, as corridas funcionam; apenas os comandos de tuning avisam que o recurso não está iniciado.
