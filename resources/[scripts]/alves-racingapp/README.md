# 🏁 Alves Racing App

Sistema de corridas simplificado para servidores Qbox/FiveM.

## 📋 Características

- ✅ **Quick Races** - Ranked e Unranked
- ✅ **Sistema ELO** - Classificação de pilotos  
- ✅ **75 Veículos JFx Classe S** - Performance máxima
- ✅ **Full Tuning Automático** - Todos os carros vêm full tuning
- ✅ **UI Integrada** - Tablet de gerenciamento + HUD de corrida
- ✅ **Proteção de Dano** - Veículos indestrutíveis durante corridas
- ✅ **Interface Moderna** - Design limpo e profissional

## 🎮 Comandos

- `/race` ou **F1** - Abrir menu de corridas
- `/sair` - Sair da corrida atual

## 📦 Dependências

- qbx_core
- ox_lib
- oxmysql

## ⚙️ Instalação

1. Copie a pasta `alves-racingapp` para `resources/[scripts]/`
2. Adicione ao `server.cfg`:
```cfg
ensure alves-racingapp
```
3. Restart servidor

## 🗄️ Banco de Dados

Utiliza as tabelas do cw-racingapp:
- `race_tracks` - Pistas
- `racer_names` - Pilotos e ELO

## 🚗 Veículos

75 carros JFx Classe S com full tuning automático:
- Performance máxima (Power x50, Torque x50)
- Todos os upgrades aplicados
- Turbo ativado
- Indestrutíveis durante corridas

## 📊 Sistema ELO

- **Inicio**: 1000 ELO
- **Ranked**: Afeta ELO
- **Unranked**: Apenas diversão

## 🎨 Interface

### Tablet de Gerenciamento
- Corrida Ranked
- Corrida Casual
- Scoreboard
- Ranking Global
- Meu Perfil

### HUD de Corrida
- Countdown (5, 4, 3, 2, 1, GO!)
- Posição atual
- Volta (1/3)
- Tempo decorrido
- Checkpoint (1/10)

## 📝 Notas

- Script otimizado e leve
- Sem features desnecessárias
- Foco em performance e simplicidade
- UI responsiva e moderna

## 👨‍💻 Autor

**Alves**  
Versão 1.0.0

---

*Sistema de corridas puro, leve e profissional para Qbox*
