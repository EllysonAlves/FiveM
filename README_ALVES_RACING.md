# Alves Racing / FiveM Qbox

Base do servidor FiveM/Qbox focado em corridas.

## Segurança

- Não commitar `server.cfg` real, chaves, tokens, webhooks, dumps SQL ou cache.
- Use `server.cfg.example` como modelo seguro.
- Depois de ter exposto keys em qualquer lugar, rotacione `sv_licenseKey` e `steam_webApiKey`.

## Resources customizados principais

- `resources/[scripts]/alves-racingapp` — painel/corridas/ranking/ELO.
- `resources/[qbx]/qbx_hud` — HUD com tema Alves Racing.
- `resources/[standalone]/loadscreen` — loading screen no tema Alves Racing.

## Testes manuais recomendados

1. Iniciar servidor.
2. Verificar console sem erro de manifest/NUI.
3. Entrar no servidor.
4. Testar `/race` e F1.
5. Iniciar corrida casual.
6. Iniciar corrida ranked.
7. Abrir Ranking e Perfil.
8. Entrar em veículo e validar HUD/velocímetro.
