# 🏁 ALVES RACING - SISTEMA DE ELO POR TIERS
### Guia de Instalação e Uso

---

## 📦 INSTALAÇÃO

### 1️⃣ Atualizar Banco de Dados

Execute o script SQL no seu banco de dados:

```bash
E:\txData\Qbox_F52520.base\resources\[scripts]\alves-racingapp\add_elo_system.sql
```

Este script adiciona as colunas necessárias:
- `elo_points` - Pontos ELO dentro do tier atual
- `elo_tier` - Tier atual do jogador

### 2️⃣ Reiniciar o Resource

```
restart alves-racingapp
```

---

## 🎮 SISTEMA DE TIERS

### 📊 Tiers Disponíveis

| Tier | Pontos | Descrição | Cor |
|------|--------|-----------|-----|
| **Street** | 0 - 100 | Novatos | Cinza |
| **Semi Slick** | 101 - 200 | Intermediário | Azul |
| **Slick** | 201 - 300 | Avançado | Roxo |
| **Profissional** | 301+ | Elite | Dourado |

### 📈 Progressão de Tier

- Complete **100 pontos** no tier atual para subir
- Ao atingir o máximo, sobe automaticamente para o próximo tier
- Notificação aparece quando você sobe de tier

---

## 🏆 SISTEMA DE PONTOS ELO

### 💰 Como Ganhar Pontos

**Apenas em CORRIDAS RANKEADAS:**

1. Complete a corrida rankeada
2. Ganhe **+20 pontos ELO** (sistema atual)
3. Pontos são salvos automaticamente
4. Progresso do tier atualizado em tempo real

### 🔮 Sistema Multiplayer (Futuro)

O sistema está preparado para corridas multiplayer:
- Top 40% dos participantes ganham pontos
- Distribuição decrescente (1º ganha mais)
- Bottom 60% perdem 10 pontos
- Exemplo com 10 participantes:
  - 1º lugar: ~50 pontos
  - 2º lugar: ~45 pontos
  - 3º lugar: ~40 pontos
  - 4º lugar: ~35 pontos
  - 5º-10º: -10 pontos

---

## 🚗 MECÂNICA DE INÍCIO DE CORRIDA

### ⏱️ Contagem Regressiva

**Antes:**
- Carro spawna e corrida começa imediatamente
- Sem tempo para se preparar

**Agora:**
1. ✅ Carro spawna na linha de largada
2. ✅ Veículo **CONGELADO** (FreezeEntityPosition)
3. ✅ Contagem de **5 segundos** no centro da tela
4. ✅ Contagem: 5... 4... 3... 2... 1... GO!
5. ✅ Veículo **LIBERADO** automaticamente
6. ✅ Corrida inicia

### 🎨 Visual da Contagem

- Números grandes no centro da tela
- Animação de pulso
- Cor laranja (#ff6b35)
- Efeito de brilho/sombra
- Transição suave para "GO!"

---

## 📊 DASHBOARD DETALHADO

### 🖥️ Interface Principal (Tablet)

**Menu Principal:**
1. 🏆 **CORRIDA RANKED** - Afeta ELO e tier
2. 🚗 **CORRIDA CASUAL** - Apenas por diversão
3. 📊 **SCOREBOARD** - Últimas corridas
4. 🌍 **RANKING GLOBAL** - Top 50 por tier
5. 👤 **MEU PERFIL** - Estatísticas e tier

### 👤 Perfil do Jogador

**Card de Tier ELO (Destaque):**
- Nome do tier atual (grande)
- Pontos totais
- Barra de progresso visual
- Progresso para próximo tier (ex: 45/100)
- Cor dinâmica baseada no tier

**Estatísticas:**
- Nome do piloto
- Posição no ranking
- Total de corridas
- Total de vitórias
- Taxa de vitória (%)
- Melhor tempo

### 🌍 Ranking Global

**Exibição:**
- Top 50 jogadores
- Ordenado por tier e pontos ELO
- Cards com badge de tier colorido
- Posição, nome, tier, pontos, corridas, vitórias
- Cores dinâmicas por tier:
  - 🟡 Profissional (dourado)
  - 🟣 Slick (roxo)
  - 🔵 Semi Slick (azul)
  - ⚪ Street (cinza)

### 📊 Scoreboard

- Top 10 tempos por pista
- Nome, veículo, tempo
- Top 3 destacados (ouro, prata, bronze)

---

## 🎨 MELHORIAS VISUAIS

### ✨ Design Moderno

**Tablet:**
- 1000x750px
- Fundo escuro gradiente translúcido
- Bordas arredondadas (24px)
- Sombras profundas
- Backdrop blur

**Modais:**
- 900px de largura
- Headers escuros com ícones FontAwesome
- Botão X com rotação 90° ao hover
- Scrollbar dourada personalizada
- Animações suaves (cubic-bezier)

**Efeitos:**
- Hover com brilho atravessando cards
- Fade in/out suaves
- Scale animations
- Gradientes modernos

---

## 🛠️ FUNCIONALIDADES TÉCNICAS

### 📂 Arquivos Modificados

**Server (`server/main.lua`):**
- Sistema de tiers ELO (4 tiers)
- Cálculo de pontos por posição
- Progressão automática de tier
- Callback getMyProfile com tier ELO
- Callback getGlobalRanking ordenado por tier
- Notificações de subida de tier

**Client (`client/main.lua`):**
- Travamento de veículo durante contagem
- FreezeEntityPosition + SetVehicleBrake
- Liberação automática após 5 segundos
- Armazenamento de veículo em CurrentRaceData

**UI (`ui/script.js`):**
- displayProfile com tier card e barra de progresso
- displayRanking com badges de tier coloridos
- Cálculo de progresso no tier atual

**CSS (`ui/style.css`):**
- .tier-card com gradiente dinâmico
- .tier-progress-bar animada
- .ranking-tier-badge com cores por tier
- Animações suaves e modernas

**SQL (`add_elo_system.sql`):**
- ALTER TABLE para adicionar colunas
- Índices para otimização
- UPDATE para jogadores existentes
- Consultas de estatísticas

---

## 🧪 TESTES

### ✅ Como Testar

1. **Executar SQL:**
   ```sql
   source E:\txData\Qbox_F52520.base\resources\[scripts]\alves-racingapp\add_elo_system.sql
   ```

2. **Reiniciar resource:**
   ```
   restart alves-racingapp
   ```

3. **Testar no jogo:**
   - Pressione **F1** ou `/race`
   - Clique em "MEU PERFIL" (ver tier e barra de progresso)
   - Clique em "RANKING GLOBAL" (ver tiers coloridos)
   - Inicie uma **CORRIDA RANKED**
   - Observe o carro congelado durante contagem
   - Complete a corrida
   - Veja notificação "+20 pontos ELO"
   - Abra perfil novamente (ver progresso atualizado)

### 🔍 Verificar Banco de Dados

```sql
-- Ver estrutura atualizada
DESCRIBE racer_names;

-- Ver estatísticas por tier
SELECT 
    elo_tier as 'Tier',
    COUNT(*) as 'Jogadores',
    AVG(elo_points) as 'Média',
    MAX(elo_points) as 'Máximo'
FROM racer_names 
WHERE active = 1
GROUP BY elo_tier;

-- Ver seu próprio progresso
SELECT racername, elo_tier, elo_points, races, wins
FROM racer_names
WHERE citizenid = 'SEU_CITIZENID'
AND active = 1;
```

---

## 🐛 TROUBLESHOOTING

### ❌ Erro: "Unknown column 'elo_points'"

**Solução:** Execute o script SQL `add_elo_system.sql`

### ❌ Perfil não mostra tier

**Solução:** 
```sql
UPDATE racer_names 
SET elo_points = 0, elo_tier = 'Street' 
WHERE elo_points IS NULL;
```

### ❌ Carro não congela na contagem

**Solução:** Verifique se o client foi atualizado. Reinicie o resource.

### ❌ Ranking não mostra cores de tier

**Solução:** Limpe o cache do navegador NUI (F5 no menu)

---

## 📝 NOTAS IMPORTANTES

### ⚠️ Compatibilidade

- Sistema funciona com banco de dados existente
- Jogadores antigos recebem tier Street automaticamente
- Não perde dados anteriores (ranking, corridas, vitórias)

### 🔄 Migração de Dados

- Jogadores existentes: tier Street, 0 pontos
- Podem subir de tier fazendo corridas rankeadas
- Sistema detecta e cria colunas automaticamente

### 🎯 Próximas Features

- [ ] Sistema multiplayer real com vários jogadores na mesma corrida
- [ ] Distribuição de pontos baseada em posição (top 40%)
- [ ] Penalidade por abandono de corrida (-15 pontos)
- [ ] Histórico de ganhos/perdas de ELO
- [ ] Recompensas por tier (crypto, carros exclusivos)
- [ ] Temporadas (reset mensal)

---

## 🎉 ENJOY!

Sistema completo de ELO por tiers implementado!

**Teste agora e suba de tier! 🏁🏆**
