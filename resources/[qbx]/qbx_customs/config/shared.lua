return {
    -- Alves Racing usa qbx_customs somente por comando (/tuning, /bennys, /custom).
    -- Zonas vazias evitam blips/markers de Los Santos Customs no mapa racing-only.
    zones = {},

    -- O menu ainda usa prices para montar descrições internas.
    -- Como abrimos via export, qbx_customs não cobra do jogador, mas esses valores precisam existir.
    prices = {
        ['cosmetic'] = 0,
        ['colors'] = 0,
        [11] = { 0, 0, 0, 0, 0 },
        [12] = { 0, 0, 0, 0 },
        [13] = { 0, 0, 0, 0, 0 },
        [15] = { 0, 0, 0, 0, 0, 0 },
        [18] = 0
    }
}
