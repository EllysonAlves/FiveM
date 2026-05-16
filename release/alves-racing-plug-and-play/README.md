# Alves Racing - pacote plug-and-play

Pacote para testar o sistema de corridas em outro servidor **Qbox/FiveM** sem levar configurações globais do servidor Alves Racing.

## O que vai no pacote

```txt
INSTALL.sql
server.cfg.example
resources/[alves]/alves-racingapp
```

## O que este pacote faz

- Tablet/dashboard de corridas.
- Menu lateral **GARAGEM** com a lista de `Config.RaceVehicles` e spawn de veículos de corrida.
- Lobby casual/ranked com votação de pista e veículo.
- Start da corrida com spawn do veículo escolhido no grid.
- Checkpoints, voltas automáticas e HUD de corrida.
- ELO/ranking.
- Histórico/scoreboard de corridas.
- Preset visual por jogador/veículo.
- Phase/ghost durante corrida para evitar colisão entre competidores.
- Veículo da corrida protegido, com combustível em 100 e sem degradação **somente enquanto a corrida está ativa**.

O `alves-racingapp` é independente: fora da corrida ele não altera ped, mapa, NPCs, HUD global, `/car`, vehiclekeys, combustível global, nitro, temperatura de pneu/freio, speedometer global ou configuração do servidor.

## O que NÃO vai no pacote

Essas coisas são configuração do servidor, não do script de corrida:

- Blip/ícone fixo no mapa.
- Ped obrigatório para todos os jogadores.
- Limpeza global de NPC/tráfego/despacho.
- Imortalidade global fora da corrida.
- Fuel global forçado.
- Anti-eject/seatbelt global.
- Comandos globais de tuning tipo `/tuning`, `/bennys`, `/custom`.
- Nitro global.
- Temperatura/desgaste/grip de pneus.
- Temperatura/força de freio.
- Speedometer/HUD global do servidor.
- Qualquer alteração de HUD global do servidor.

Se o servidor quiser esses comportamentos, ele deve configurar isso nos próprios resources do servidor, separado do `alves-racingapp`. No servidor Alves Racing, isso fica no `alves-racing-core`.

## Requisitos no servidor do seu colega

Obrigatórios:

- `qbx_core`
- `ox_lib`
- `oxmysql`
- banco MySQL/MariaDB configurado no servidor

Opcional:

- Qualquer pack/resource de veículos addon/custom, caso ele queira usar carros além dos vanilla.

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

# Se usar veículos addon/custom, inicie eles antes do alves-racingapp.
# Exemplos:
# ensure [carros]
# ensure vipcars

setr alves:themePrimary "#8b5cf6"
setr alves:themeBackground "#080712"

ensure alves-racingapp
```

4. Reinicie o servidor ou rode no console:

```txt
refresh
ensure alves-racingapp
```

## Como testar

- `F1` ou `/race` abre o tablet de corrida.
- Clique em Casual ou Ranked para entrar no lobby.
- Vote no mapa/carro e aguarde a contagem.
- `F2` abre/fecha lobby minimizado.
- `F3` sai do lobby.
- `/sair` sai da corrida.
- Menu **GARAGEM** lista/spawna os veículos configurados para corrida.
- `/salvarpreset` ou o botão **Salvar visual atual** na garagem salva o visual atual do veículo para aquele modelo.

## Carros do pacote

A lista de carros fica em:

```txt
resources/[alves]/alves-racingapp/config.lua
```

Edite `Config.RaceVehicles` com os **spawn names** dos carros que existem na base:

```lua
Config.RaceVehicles = {
    'sultanrs',
    'elegy',
    'jester3',
    'comet5',
    'meucarroaddon',
}
```

Não importa se o carro está em `[JFx]`, `[carros]`, `vipcars`, `donatecars` ou qualquer outro resource. O que importa é:

1. o resource do carro iniciar antes do `alves-racingapp`;
2. o spawn name estar correto em `Config.RaceVehicles`.

Se um modelo não existir/carregar, o client usa fallback `sultanrs` e mostra erro no console/notificação em vez de travar em tela preta.

## Observações

- O banco precisa ter pelo menos uma pista. O `INSTALL.sql` já cria uma pista demo.
- Para produção, substitua a pista demo pelas pistas reais do servidor.
- O pacote não mexe em `/car` ou spawn normal do servidor. Se carro fora da corrida nascer quebrado, a origem deve ser outro resource do servidor.
- Dentro da corrida, o veículo spawnado pelo lobby é corrigido/protegido, mantém combustível cheio e usa phase/ghost quando configurado.
- Ao sair/finalizar a corrida, o app remove ghost/invencibilidade e devolve o veículo ao comportamento normal do servidor.
