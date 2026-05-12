# Alves Racing App - Patch Alvinho

Versão ajustada para virar uma base mais profissional do servidor de corridas.

## O que foi alterado

- Corrigido `fxmanifest.lua` removendo arquivo inexistente `ui/tablet-new.css`.
- Adicionado `config.lua` centralizando tema, GPS, checkpoint, voltas automáticas, ELO e validações.
- UI reescrita sem jQuery/CDN externa.
- Removidos assets externos do painel para evitar interface quebrada sem internet.
- Scoreboard agora funciona mesmo sem pista selecionada, mostrando ranking global de tempos.
- Adicionado callback `alves-racingapp:getTracks` para futura tela de seleção de pistas.
- Menu lateral agora tem Perfil funcional e placeholders controlados para Garagem/Configurações.
- ESC não esconde mais HUD/countdown durante corrida, evitando corrida sem HUD.
- Corrida agora envia `totalRacers` vindo do server/config; solo fica `1/1` em vez de `1/3` fake.
- Server valida `raceId`, dono da corrida, nome da pista e tempo mínimo/máximo antes de salvar tempo.
- ELO ranked usa o tipo da corrida salvo no server, não o valor enviado pelo client.
- Estatísticas do player usam `racerid` em `track_times`, compatível com a estrutura usada no insert.
- Adicionado velocímetro NUI com tema roxo/preto do servidor.

## Pontos que ainda dependem da estrutura do seu servidor

Para eu fechar 100% redondo, preciso depois destes arquivos/informações:

1. `server.cfg` sem license key/senhas.
2. Estrutura real das tabelas:
   - `race_tracks`
   - `racer_names`
   - `track_times`
3. Nome do resource de combustível, se usa algum.
4. Se você já tem HUD/velocímetro atual, mandar o resource para evitar conflito.
5. Lista dos resources principais do servidor para eu padronizar tema.

## Próxima fase recomendada

- Tela de seleção de pistas.
- Garagem com veículos permitidos por classe/tier.
- Lobby multiplayer casual/ranked.
- Ranking semanal/mensal/temporada.
- Validação avançada de checkpoints no server.
- Padronização visual de todo o servidor: HUD, notify, loading screen, spawn selector, garagem e menus.
