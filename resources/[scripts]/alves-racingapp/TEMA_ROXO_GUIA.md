# 🎨 Guia de Tema Roxo - Alves Racing

## ✅ Já Implementado no alves-racingapp

### HUD de Corrida
- ✅ Header "ALVES RACING" com subtítulo "↓ CORRIDA DE RUA"
- ✅ Campo "MELHOR VOLTA" adicionado
- ✅ Formato de tempo com milissegundos: `00:00.000`
- ✅ Posição mostra total de corredores: `1º / 3`
- ✅ Background escuro com 85% opacidade
- ✅ Border roxa com glow (#8b5cf6)
- ✅ Layout compacto de 320px

### Tema de Cores
- 🟣 **Roxo primário**: `#8b5cf6` (violet-500)
- 🟣 **Roxo claro**: `#a855f7` (violet-400)
- 🟣 **Roxo pastel**: `#c084fc` (violet-300)
- 🟣 **Roxo escuro**: `#7c3aed` (violet-600)

### Menu/Tablet
- ✅ Todos os ícones atualizados com gradientes roxos
- ✅ Ranking e scoreboard com tema roxo
- ✅ Contagem regressiva com glow roxo animado

---

## ⚠️ Para Implementar em Outros Scripts

### 1. Velocímetro (qbx_hud ou similar)

**Localização**: `resources/[qbx]/qbx_hud/html/` ou similar

**Alterações necessárias**:

```css
/* Encontre o velocímetro e altere as cores */
.speedometer-circle {
    border: 3px solid #8b5cf6; /* Roxo ao invés de verde/amarelo */
    box-shadow: 0 0 30px rgba(139, 92, 246, 0.6);
}

.speedometer-value {
    color: #a855f7;
    text-shadow: 0 0 20px rgba(168, 85, 247, 0.8);
}
```

---

### 2. Notificações Globais (ox_lib)

**Localização**: `resources/[standalone]/ox_lib/web/` ou `node_modules/@overextended/ox_lib/web/`

**Método 1 - Arquivo CSS personalizado**:

Crie `custom-notifications.css` no seu resource:

```css
/* Override das notificações ox_lib */
.notification {
    background: rgba(15, 15, 25, 0.90) !important;
    border-left: 4px solid #8b5cf6 !important;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6), 0 0 20px rgba(139, 92, 246, 0.3) !important;
}

.notification-icon {
    color: #a855f7 !important;
}

.notification.success {
    border-left-color: #8b5cf6 !important;
}

.notification.inform {
    border-left-color: #a855f7 !important;
}

.notification.error {
    border-left-color: #ef4444 !important;
}
```

**Método 2 - Editar ox_lib diretamente**:

Edite `ox_lib/web/notifications.css` (ou `styles.css`) e substitua:
- Verde por roxo: `#10b981` → `#8b5cf6`
- Azul por roxo claro: `#3b82f6` → `#a855f7`

---

### 3. Chat (chat resource)

**Localização**: `resources/[cfx-default]/[system]/chat/html/`

```css
/* chat.css */
.message {
    background: rgba(15, 15, 25, 0.85);
    border-left: 3px solid #8b5cf6;
}

.message-author {
    color: #a855f7;
}
```

---

### 4. Outros HUDs

**qbx_hud, qb-hud, etc.**:

Procure por cores hexadecimais e substitua:
- `#fbbf24` (dourado) → `#8b5cf6` (roxo)
- `#f59e0b` (laranja) → `#a855f7` (roxo claro)
- `#10b981` (verde) → `#8b5cf6` (roxo)
- `#3b82f6` (azul) → `#a855f7` (roxo claro)

---

## 📦 Palette Completa

Use estas cores para manter consistência:

```css
/* Roxos principais */
--purple-dark: #7c3aed;    /* Escuro */
--purple-main: #8b5cf6;    /* Principal */
--purple-light: #a855f7;   /* Claro */
--purple-pastel: #c084fc;  /* Pastel */

/* RGBa para transparências */
--purple-dark-rgba: rgba(124, 58, 237, 0.X);
--purple-main-rgba: rgba(139, 92, 246, 0.X);
--purple-light-rgba: rgba(168, 85, 247, 0.X);
--purple-pastel-rgba: rgba(192, 132, 252, 0.X);

/* Backgrounds */
--bg-dark: rgba(15, 15, 25, 0.85);
--bg-darker: rgba(10, 10, 20, 0.90);
```

---

## 🛠️ Como Aplicar

1. **Backup**: Faça backup dos arquivos originais
2. **Edite CSS**: Abra os arquivos CSS dos scripts
3. **Substitua cores**: Use buscar/substituir (Ctrl+H)
4. **Teste**: Reinicie o resource e teste no jogo
5. **Ajuste**: Refine opacidades e glows conforme necessário

---

## 💡 Dica Pro

Para substituir cores em massa via PowerShell:

```powershell
$file = "caminho/para/arquivo.css"
$content = Get-Content -LiteralPath $file -Raw
$content = $content -replace '#fbbf24', '#8b5cf6'
$content = $content -replace '#f59e0b', '#a855f7'
$content = $content -replace 'rgba\(251, 191, 36,', 'rgba(139, 92, 246,'
Set-Content -LiteralPath $file -Value $content -NoNewline
```

---

## 📧 Suporte

Se tiver dúvidas sobre quais arquivos editar, me avise o nome do script e posso ajudar a localizar!
