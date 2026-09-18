/*
 * FFXI Advance - Game State, Combat & SRAM Save Implementation
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#include "game_state.h"
#include "graphics.h"
#include "audio.h"

PlayerState g_player;
CombatLog   g_log;
Monster     g_mobs[MAX_ZONE_MOBS];
int         g_mob_count = 0;
NPC         g_npcs[MAX_ZONE_NPCS];
int         g_npc_count = 0;
GameScreen  g_current_screen = SCREEN_TITLE;

static void str_copy(char* dest, const char* src, int max_len) {
    int i = 0;
    while (src && src[i] && i < max_len - 1) {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
}

void game_init_defaults(void) {
    str_copy(g_player.name, "Daniel", 16);
    g_player.race = RACE_HUME;
    g_player.job = JOB_WARRIOR;
    g_player.subjob = 255; // No subjob initially
    g_player.nation = NATION_SANDORIA;
    g_player.level = 1;
    g_player.exp = 0;
    g_player.exp_to_next = 500;
    g_player.max_hp = 50;
    g_player.hp = 50;
    g_player.max_mp = 0;
    g_player.mp = 0;
    g_player.tp = 0;
    g_player.gil = 500;

    g_player.str = 12;
    g_player.dex = 10;
    g_player.vit = 11;
    g_player.agi = 10;
    g_player.int_ = 9;
    g_player.mnd = 9;
    g_player.chr = 10;
    g_player.attack = 18;
    g_player.defense = 14;

    g_player.zone_id = ZONE_SANDORIA;
    g_player.x = 10;
    g_player.y = 8;
    g_player.dir = 0;
    g_player.resting = false;
    g_player.rest_timer = 0;

    g_player.in_combat = false;
    g_player.target_index = -1;
    g_player.weapon_delay_timer = 0;
    g_player.weapon_delay_max = 60; // 1 second @ 60fps

    g_player.rank_mission_active = false;
    g_player.rank_mission_done = false;
    g_player.signet_active = true;
    g_player.subjob_quest_active = false;
    g_player.subjob_quest_done = false;

    // Starter inventory: Potion x3
    g_player.inventory[0].item_id = 1; // Potion
    g_player.inventory[0].quantity = 3;

    for (int i = 0; i < MAX_COMBAT_LOGS; i++) {
        g_log.lines[i][0] = '\0';
        g_log.colors[i] = COLOR_WHITE;
    }
    g_log.head = 0;
}

void game_start_new(const char* name, int race, int job, int nation) {
    game_init_defaults();
    if (name && name[0] != '\0') {
        str_copy(g_player.name, name, 16);
    }
    g_player.race = (u8)race;
    g_player.job = (u8)job;
    g_player.nation = (u8)nation;

    // Racial adjustments
    if (race == RACE_ELVAAN) {
        g_player.str += 3;
        g_player.mnd += 2;
        g_player.int_ -= 2;
    } else if (race == RACE_TARUTARU) {
        g_player.int_ += 4;
        g_player.str -= 3;
        g_player.max_mp += 30;
    } else if (race == RACE_MITHRA) {
        g_player.dex += 3;
        g_player.agi += 3;
        g_player.str -= 1;
    } else if (race == RACE_GALKA) {
        g_player.max_hp += 25;
        g_player.vit += 3;
    }

    // Job adjustments
    if (job == JOB_MONK) {
        g_player.max_hp += 15;
        g_player.str += 2;
        g_player.weapon_delay_max = 45; // Faster fists
    } else if (job == JOB_WHITE_MAGE) {
        g_player.max_mp += 25;
        g_player.mnd += 3;
        g_player.weapon_delay_max = 65;
    } else if (job == JOB_BLACK_MAGE) {
        g_player.max_mp += 35;
        g_player.int_ += 3;
        g_player.weapon_delay_max = 65;
    } else if (job == JOB_RED_MAGE) {
        g_player.max_mp += 18;
        g_player.str += 1;
        g_player.int_ += 1;
        g_player.mnd += 1;
    } else if (job == JOB_THIEF) {
        g_player.dex += 2;
        g_player.agi += 2;
        g_player.weapon_delay_max = 45; // Swift dagger
    }

    g_player.hp = g_player.max_hp;
    g_player.mp = g_player.max_mp;

    // Starting zone based on Nation
    if (nation == NATION_BASTOK) {
        game_change_zone(ZONE_BASTOK, 10, 8);
    } else if (nation == NATION_WINDURST) {
        game_change_zone(ZONE_WINDURST, 10, 8);
    } else {
        game_change_zone(ZONE_SANDORIA, 10, 8);
    }

    game_log_add("Welcome to Vana'diel!", COLOR_GOLD);
    game_log_add("Protect the Realm!", COLOR_CYAN);
}

void game_log_add(const char* msg, u16 color) {
    str_copy(g_log.lines[g_log.head], msg, 36);
    g_log.colors[g_log.head] = color;
    g_log.head = (g_log.head + 1) % MAX_COMBAT_LOGS;
}

void game_change_zone(ZoneID new_zone, int spawn_x, int spawn_y) {
    g_player.zone_id = (u8)new_zone;
    g_player.x = (u8)spawn_x;
    g_player.y = (u8)spawn_y;
    g_player.in_combat = false;
    g_player.target_index = -1;
    g_mob_count = 0;
    g_npc_count = 0;

    audio_play_sfx(SFX_ZONE);

    if (new_zone == ZONE_SANDORIA) {
        audio_play_bgm(BGM_RONFAURE);
        str_copy(g_npcs[0].name, "Gate Guard", 16);
        g_npcs[0].x = 10; g_npcs[0].y = 3;
        g_npcs[0].text = "Signet has been cast upon you!";
        str_copy(g_npcs[1].name, "Moogle", 16);
        g_npcs[1].x = 4; g_npcs[1].y = 4;
        g_npcs[1].text = "Kupo! Your Mog House is safe!";
        g_npc_count = 2;
    }
    else if (new_zone == ZONE_WEST_RONFAURE) {
        audio_play_bgm(BGM_RONFAURE);
        // Spawn Wild Rabbits and Funguars
        for (int i = 0; i < 4; i++) {
            str_copy(g_mobs[i].name, (i % 2 == 0) ? "Wild Rabbit" : "Forest Funguar", 16);
            g_mobs[i].type = (i % 2 == 0) ? MOB_WILD_RABBIT : MOB_FOREST_FUNGUAR;
            g_mobs[i].level = (i < 2) ? 1 : 2;
            g_mobs[i].max_hp = 30 + (i * 10);
            g_mobs[i].hp = g_mobs[i].max_hp;
            g_mobs[i].attack = 8 + i;
            g_mobs[i].defense = 8 + i;
            g_mobs[i].exp_reward = 35 + (i * 15);
            g_mobs[i].gil_reward = 12 + (i * 8);
            g_mobs[i].x = 5 + (i * 4);
            g_mobs[i].y = 4 + (i * 2);
            g_mobs[i].alive = true;
            g_mobs[i].respawn_timer = 0;
            g_mobs[i].attack_timer = 0;
        }
        g_mob_count = 4;
    }
    else if (new_zone == ZONE_VALKURM_DUNES) {
        audio_play_bgm(BGM_BATTLE);
        for (int i = 0; i < 4; i++) {
            str_copy(g_mobs[i].name, (i % 2 == 0) ? "Damselfly" : "Goblin Thug", 16);
            g_mobs[i].type = (i % 2 == 0) ? MOB_DAMSELFLY : MOB_GOBLIN_THUG;
            g_mobs[i].level = 10 + i;
            g_mobs[i].max_hp = 120 + (i * 20);
            g_mobs[i].hp = g_mobs[i].max_hp;
            g_mobs[i].attack = 25 + (i * 4);
            g_mobs[i].defense = 22 + (i * 3);
            g_mobs[i].exp_reward = 120 + (i * 30);
            g_mobs[i].gil_reward = 60 + (i * 20);
            g_mobs[i].x = 4 + (i * 4);
            g_mobs[i].y = 5 + (i * 2);
            g_mobs[i].alive = true;
            g_mobs[i].respawn_timer = 0;
            g_mobs[i].attack_timer = 0;
        }
        g_mob_count = 4;
    }
    else if (new_zone == ZONE_SELBINA) {
        audio_play_bgm(BGM_RONFAURE);
        str_copy(g_npcs[0].name, "Isacio", 16);
        g_npcs[0].x = 8; g_npcs[0].y = 5;
        g_npcs[0].text = "Bring me items for your Subjob!";
        g_npc_count = 1;
    }
    else {
        // Bastok / Windurst / Gustaberg / Sarutabaruta default
        audio_play_bgm(BGM_RONFAURE);
        for (int i = 0; i < 3; i++) {
            str_copy(g_mobs[i].name, "Mandragora", 16);
            g_mobs[i].type = MOB_MANDRAGORA;
            g_mobs[i].level = 1;
            g_mobs[i].max_hp = 25;
            g_mobs[i].hp = 25;
            g_mobs[i].attack = 7;
            g_mobs[i].defense = 6;
            g_mobs[i].exp_reward = 30;
            g_mobs[i].gil_reward = 10;
            g_mobs[i].x = 6 + (i * 4);
            g_mobs[i].y = 5;
            g_mobs[i].alive = true;
            g_mobs[i].respawn_timer = 0;
            g_mobs[i].attack_timer = 0;
        }
        g_mob_count = 3;
    }
}

void game_tick_resting(void) {
    if (!g_player.resting) return;
    g_player.rest_timer++;
    if (g_player.rest_timer >= 60) { // Every ~1 sec while resting
        g_player.rest_timer = 0;
        bool healed = false;
        if (g_player.hp < g_player.max_hp) {
            g_player.hp += 5 + (g_player.level * 2);
            if (g_player.hp > g_player.max_hp) g_player.hp = g_player.max_hp;
            healed = true;
        }
        if (g_player.mp < g_player.max_mp) {
            g_player.mp += 6 + (g_player.level * 2);
            if (g_player.mp > g_player.max_mp) g_player.mp = g_player.max_mp;
            healed = true;
        }
        if (healed) {
            audio_play_sfx(SFX_CURE);
        }
    }
}

void game_check_level_up(void) {
    if (g_player.exp >= g_player.exp_to_next) {
        g_player.exp -= g_player.exp_to_next;
        g_player.level++;
        g_player.exp_to_next = g_player.level * 750;

        g_player.max_hp += 12;
        g_player.hp = g_player.max_hp;
        if (g_player.max_mp > 0 || g_player.job == JOB_WHITE_MAGE || g_player.job == JOB_BLACK_MAGE || g_player.job == JOB_RED_MAGE) {
            g_player.max_mp += 10;
            g_player.mp = g_player.max_mp;
        }
        g_player.attack += 3;
        g_player.defense += 2;
        g_player.str += 1;
        g_player.dex += 1;
        g_player.vit += 1;

        audio_play_sfx(SFX_LEVEL_UP);
        game_log_add("LEVEL UP!", COLOR_GOLD);
        char buf[36];
        buf[0] = 'N'; buf[1] = 'o'; buf[2] = 'w'; buf[3] = ' ';
        buf[4] = 'L'; buf[5] = 'e'; buf[6] = 'v'; buf[7] = 'e'; buf[8] = 'l'; buf[9] = ' ';
        buf[10] = '0' + (g_player.level / 10);
        buf[11] = '0' + (g_player.level % 10);
        buf[12] = '!'; buf[13] = '\0';
        game_log_add(buf, COLOR_YELLOW);
    }
}

void combat_engage_target(int mob_index) {
    if (mob_index < 0 || mob_index >= g_mob_count) return;
    if (!g_mobs[mob_index].alive) return;

    g_player.in_combat = true;
    g_player.target_index = mob_index;
    g_player.resting = false;
    g_player.weapon_delay_timer = 0;

    audio_play_sfx(SFX_CONFIRM);
    audio_play_bgm(BGM_BATTLE);

    char buf[36];
    str_copy(buf, "Engaged ", 36);
    int len = 8;
    for (int i = 0; g_mobs[mob_index].name[i] && len < 34; i++) {
        buf[len++] = g_mobs[mob_index].name[i];
    }
    buf[len] = '\0';
    game_log_add(buf, COLOR_CYAN);
}

void combat_disengage(void) {
    g_player.in_combat = false;
    g_player.target_index = -1;
    audio_play_sfx(SFX_CANCEL);
    game_log_add("Disengaged.", COLOR_GRAY);
    audio_play_bgm(BGM_RONFAURE);
}

void combat_execute_attack(void) {
    int t = g_player.target_index;
    if (t < 0 || t >= g_mob_count || !g_mobs[t].alive) {
        combat_disengage();
        return;
    }

    Monster* m = &g_mobs[t];
    // Damage calculation: (Attack - Defense/2) + d8
    int dmg = (g_player.attack - (m->defense / 2));
    if (dmg < 1) dmg = 1;
    dmg += (g_player.str % 5);

    // Critical hit check
    bool crit = (g_player.dex % 6 == 0);
    if (crit) {
        dmg = (dmg * 3) / 2;
        audio_play_sfx(SFX_CRITICAL);
    } else {
        audio_play_sfx(SFX_ATTACK);
    }

    m->hp -= dmg;

    // Gain 120 TP per hit (up to 3000)
    g_player.tp += 120;
    if (g_player.tp > 3000) g_player.tp = 3000;

    char buf[36];
    str_copy(buf, crit ? "Critical hit! " : "Hits for ", 36);
    int blen = crit ? 14 : 9;
    if (dmg >= 100) { buf[blen++] = '0' + (dmg / 100); }
    if (dmg >= 10)  { buf[blen++] = '0' + ((dmg / 10) % 10); }
    buf[blen++] = '0' + (dmg % 10);
    buf[blen++] = ' '; buf[blen++] = 'd'; buf[blen++] = 'm'; buf[blen++] = 'g';
    buf[blen] = '\0';
    game_log_add(buf, crit ? COLOR_YELLOW : COLOR_WHITE);

    if (m->hp <= 0) {
        m->hp = 0;
        m->alive = false;
        m->respawn_timer = 180; // ~3 seconds respawn
        g_player.in_combat = false;
        g_player.target_index = -1;

        audio_play_sfx(SFX_CONFIRM);
        audio_play_bgm(BGM_VICTORY);

        game_log_add("Target defeated!", COLOR_GOLD);
        g_player.exp += m->exp_reward;
        g_player.gil += m->gil_reward;

        game_check_level_up();
    }
}

void combat_execute_ws(int ws_id) {
    if (g_player.tp < 1000) {
        audio_play_sfx(SFX_CANCEL);
        game_log_add("Not enough TP! (1000 needed)", COLOR_RED);
        return;
    }

    int t = g_player.target_index;
    if (t < 0 || t >= g_mob_count || !g_mobs[t].alive) return;

    Monster* m = &g_mobs[t];
    g_player.tp -= 1000;

    int dmg = (g_player.attack * 2) + 15;
    m->hp -= dmg;
    audio_play_sfx(SFX_CRITICAL);

    const char* ws_names[] = {"Fast Blade", "Combo", "Red Lotus Blade", "Viper Bite"};
    const char* name = (ws_id >= 0 && ws_id < 4) ? ws_names[ws_id] : "Weapon Skill";

    char buf[36];
    str_copy(buf, name, 36);
    game_log_add(buf, COLOR_ORANGE);

    if (m->hp <= 0) {
        m->hp = 0;
        m->alive = false;
        m->respawn_timer = 180;
        g_player.in_combat = false;
        audio_play_bgm(BGM_VICTORY);
        game_log_add("Target defeated!", COLOR_GOLD);
        g_player.exp += m->exp_reward;
        g_player.gil += m->gil_reward;
        game_check_level_up();
    }
}

void combat_cast_spell(int spell_id) {
    if (spell_id == 0) { // Cure (8 MP)
        if (g_player.mp < 8) {
            audio_play_sfx(SFX_CANCEL);
            game_log_add("Not enough MP!", COLOR_RED);
            return;
        }
        g_player.mp -= 8;
        int heal = 35 + (g_player.mnd / 2);
        g_player.hp += heal;
        if (g_player.hp > g_player.max_hp) g_player.hp = g_player.max_hp;
        audio_play_sfx(SFX_CURE);
        game_log_add("Cure casts! Recovered HP.", COLOR_GREEN);
    } else if (spell_id == 1) { // Stone (9 MP)
        if (g_player.mp < 9) {
            audio_play_sfx(SFX_CANCEL);
            game_log_add("Not enough MP!", COLOR_RED);
            return;
        }
        int t = g_player.target_index;
        if (t < 0 || t >= g_mob_count || !g_mobs[t].alive) return;
        g_player.mp -= 9;
        int dmg = 28 + (g_player.int_ / 2);
        g_mobs[t].hp -= dmg;
        audio_play_sfx(SFX_MAGIC_CAST);
        game_log_add("Stone strikes target!", COLOR_YELLOW);
        if (g_mobs[t].hp <= 0) {
            g_mobs[t].alive = false;
            g_mobs[t].respawn_timer = 180;
            g_player.in_combat = false;
            audio_play_bgm(BGM_VICTORY);
            game_log_add("Target defeated!", COLOR_GOLD);
            g_player.exp += g_mobs[t].exp_reward;
            g_player.gil += g_mobs[t].gil_reward;
            game_check_level_up();
        }
    }
}

void combat_mob_tick(void) {
    for (int i = 0; i < g_mob_count; i++) {
        Monster* m = &g_mobs[i];
        if (!m->alive) {
            if (m->respawn_timer > 0) {
                m->respawn_timer--;
                if (m->respawn_timer == 0) {
                    m->alive = true;
                    m->hp = m->max_hp;
                }
            }
            continue;
        }

        // If target is locked and player in combat with this mob
        if (g_player.in_combat && g_player.target_index == i) {
            m->attack_timer++;
            if (m->attack_timer >= 75) { // Mob attacks every 1.25s
                m->attack_timer = 0;
                int mob_dmg = m->attack - (g_player.defense / 2);
                if (mob_dmg < 1) mob_dmg = 1;
                g_player.hp -= mob_dmg;
                audio_play_sfx(SFX_ATTACK);

                char buf[36];
                str_copy(buf, m->name, 36);
                int len = 0; while (buf[len]) len++;
                buf[len++] = ' '; buf[len++] = 'h'; buf[len++] = 'i'; buf[len++] = 't'; buf[len++] = 's'; buf[len++] = '!';
                buf[len] = '\0';
                game_log_add(buf, COLOR_RED);

                if (g_player.hp <= 0) {
                    g_player.hp = 0;
                    g_player.in_combat = false;
                    audio_play_sfx(SFX_DEFEAT);
                    g_current_screen = SCREEN_GAME_OVER;
                }
            }
        }
    }
}

/* SRAM Storage structure with checksum */
#define SRAM_MAGIC 0x46465849 // "FFXI"
typedef struct {
    u32 magic;
    PlayerState player;
    u32 checksum;
} SRAMHeader;

bool save_game_to_sram(void) {
    SRAMHeader header;
    header.magic = SRAM_MAGIC;
    header.player = g_player;

    u32 chk = 0;
    const u8* ptr = (const u8*)&header.player;
    for (u32 i = 0; i < sizeof(PlayerState); i++) {
        chk += ptr[i];
    }
    header.checksum = chk;

    vu8* sram = MEM_SRAM;
    const u8* src = (const u8*)&header;
    for (u32 i = 0; i < sizeof(SRAMHeader); i++) {
        sram[i] = src[i];
    }
    game_log_add("Game saved to battery SRAM!", COLOR_GOLD);
    audio_play_sfx(SFX_CONFIRM);
    return true;
}

bool has_valid_save_in_sram(void) {
    vu8* sram = MEM_SRAM;
    SRAMHeader header;
    u8* dest = (u8*)&header;
    for (u32 i = 0; i < sizeof(SRAMHeader); i++) {
        dest[i] = sram[i];
    }
    if (header.magic != SRAM_MAGIC) return false;

    u32 chk = 0;
    const u8* ptr = (const u8*)&header.player;
    for (u32 i = 0; i < sizeof(PlayerState); i++) {
        chk += ptr[i];
    }
    return (header.checksum == chk);
}

bool load_game_from_sram(void) {
    if (!has_valid_save_in_sram()) return false;

    vu8* sram = MEM_SRAM;
    SRAMHeader header;
    u8* dest = (u8*)&header;
    for (u32 i = 0; i < sizeof(SRAMHeader); i++) {
        dest[i] = sram[i];
    }
    g_player = header.player;
    game_change_zone((ZoneID)g_player.zone_id, g_player.x, g_player.y);
    game_log_add("Game loaded from SRAM!", COLOR_GREEN);
    audio_play_sfx(SFX_CONFIRM);
    return true;
}
