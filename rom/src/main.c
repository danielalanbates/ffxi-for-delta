/*
 * FFXI Advance (FINAL FANTASY XI for Delta)
 * Main Game Loop, Screen States, and Input Handler
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#include "gba.h"
#include "graphics.h"
#include "audio.h"
#include "game_state.h"

static InputState input;
static int menu_cursor = 0;
static int create_race = RACE_HUME;
static int create_job = JOB_WARRIOR;
static int create_nation = NATION_SANDORIA;
static int create_step = 0; // 0: Race, 1: Job, 2: Nation
static u32 frame_counter = 0;

/* Title Screen */
static void update_title_screen(void) {
    bool has_save = has_valid_save_in_sram();
    int max_opt = has_save ? 2 : 1;

    if (input_is_pressed(&input, KEY_DOWN)) {
        menu_cursor = (menu_cursor + 1) % (max_opt + 1);
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_UP)) {
        menu_cursor = (menu_cursor + max_opt) % (max_opt + 1);
        audio_play_sfx(SFX_CURSOR);
    }

    if (input_is_pressed(&input, KEY_A) || input_is_pressed(&input, KEY_START)) {
        audio_play_sfx(SFX_CONFIRM);
        if (menu_cursor == 0) {
            // New Game
            g_current_screen = SCREEN_CHAR_CREATE;
            create_step = 0;
            menu_cursor = 0;
        } else if (has_save && menu_cursor == 1) {
            // Continue
            load_game_from_sram();
            g_current_screen = SCREEN_ZONE_EXPLORE;
        }
    }
}

static void draw_title_screen(void) {
    gfx_clear(RGB15(1, 2, 6));

    // Animated starry/crystal background lines
    for (int y = 0; y < 160; y += 8) {
        gfx_draw_hline(0, y, 240, RGB15(2, 3, 8));
    }

    // Title Logo Box
    gfx_draw_window(15, 12, 210, 52, 0);
    gfx_draw_string_shadow(32, 20, "FINAL FANTASY XI", COLOR_GOLD);
    gfx_draw_string(45, 34, "Vana'diel Advance", COLOR_WHITE, 0, true);
    gfx_draw_string(62, 46, "Built for Delta iOS", COLOR_CYAN, 0, true);

    // Menu Box
    bool has_save = has_valid_save_in_sram();
    gfx_draw_window(55, 76, 130, 54, 0);

    gfx_draw_string(80, 84, "New Game", (menu_cursor == 0) ? COLOR_GOLD : COLOR_WHITE, 0, true);
    if (has_save) {
        gfx_draw_string(80, 96, "Continue", (menu_cursor == 1) ? COLOR_GOLD : COLOR_WHITE, 0, true);
        gfx_draw_string(80, 108, "Credits", (menu_cursor == 2) ? COLOR_GOLD : COLOR_WHITE, 0, true);
    } else {
        gfx_draw_string(80, 96, "Credits", (menu_cursor == 1) ? COLOR_GOLD : COLOR_WHITE, 0, true);
    }

    // Cursor Hand / Arrow
    int cy = 84 + (menu_cursor * 12);
    gfx_draw_string(68, cy, ">", COLOR_GOLD, 0, true);

    // Footer
    gfx_draw_string(30, 142, "(c) 2026 Bates LLC / batesai.org", COLOR_GRAY, 0, true);
}

/* Character Creation Screen */
static void update_char_create(void) {
    if (create_step == 0) { // Select Race
        if (input_is_pressed(&input, KEY_RIGHT)) {
            create_race = (create_race + 1) % RACE_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_LEFT)) {
            create_race = (create_race + RACE_COUNT - 1) % RACE_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_A)) {
            audio_play_sfx(SFX_CONFIRM);
            create_step = 1;
        }
    } else if (create_step == 1) { // Select Job
        if (input_is_pressed(&input, KEY_RIGHT)) {
            create_job = (create_job + 1) % JOB_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_LEFT)) {
            create_job = (create_job + JOB_COUNT - 1) % JOB_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_B)) {
            audio_play_sfx(SFX_CANCEL);
            create_step = 0;
        }
        if (input_is_pressed(&input, KEY_A)) {
            audio_play_sfx(SFX_CONFIRM);
            create_step = 2;
        }
    } else if (create_step == 2) { // Select Nation
        if (input_is_pressed(&input, KEY_RIGHT)) {
            create_nation = (create_nation + 1) % NATION_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_LEFT)) {
            create_nation = (create_nation + NATION_COUNT - 1) % NATION_COUNT;
            audio_play_sfx(SFX_CURSOR);
        }
        if (input_is_pressed(&input, KEY_B)) {
            audio_play_sfx(SFX_CANCEL);
            create_step = 1;
        }
        if (input_is_pressed(&input, KEY_A)) {
            audio_play_sfx(SFX_CONFIRM);
            game_start_new("Daniel", create_race, create_job, create_nation);
            g_current_screen = SCREEN_ZONE_EXPLORE;
        }
    }
}

static void draw_char_create(void) {
    gfx_clear(RGB15(2, 3, 7));

    gfx_draw_window(10, 8, 220, 24, 0);
    const char* step_titles[] = {
        "Select Race (D-Pad < >)",
        "Select Starter Job (D-Pad < >)",
        "Select Starting Nation"
    };
    gfx_draw_string(20, 16, step_titles[create_step], COLOR_GOLD, 0, true);

    // Left Box: Character Preview
    gfx_draw_window(10, 36, 100, 115, "Character");
    gfx_draw_player_sprite(45, 60, create_race, create_job, 0, (frame_counter / 15) % 2);

    const char* race_names[] = {"Hume", "Elvaan", "Tarutaru", "Mithra", "Galka"};
    const char* job_names[] = {"Warrior (WAR)", "Monk (MNK)", "White Mage (WHM)", "Black Mage (BLM)", "Red Mage (RDM)", "Thief (THF)"};
    const char* nation_names[] = {"San d'Oria", "Bastok", "Windurst"};

    gfx_draw_string(20, 85, race_names[create_race], COLOR_WHITE, 0, true);
    gfx_draw_string(15, 100, job_names[create_job], COLOR_CYAN, 0, true);
    gfx_draw_string(20, 115, nation_names[create_nation], COLOR_GOLD, 0, true);

    // Right Box: Description & Stats
    gfx_draw_window(115, 36, 115, 115, "Details");
    if (create_step == 0) {
        const char* race_desc[] = {
            "Balanced stats\n adaptable in\n all 6 jobs.",
            "Proud knights.\n High STR & MND,\n low INT.",
            "Masters of magic\n Vast MP pool\n high INT.",
            "Agile hunters.\n High DEX & AGI,\n deadly strikes.",
            "Mighty giants.\n Enormous HP\n & heavy defense."
        };
        gfx_draw_string(122, 55, race_desc[create_race], COLOR_WHITE, 0, true);
    } else if (create_step == 1) {
        const char* job_desc[] = {
            "Melee frontliner\n Heavy armor\n Provoke ability.",
            "Martial artist\n High HP & bare\n fist strikes.",
            "Holy healer.\n Cure spells &\n divine protection.",
            "Destructive art.\n Elemental black\n magic spells.",
            "Versatile hybrid\n White/Black magic\n & swordplay.",
            "Agile rogue.\n Fast daggers &\n Sneak Attack."
        };
        gfx_draw_string(122, 55, job_desc[create_job], COLOR_WHITE, 0, true);
    } else {
        const char* nation_desc[] = {
            "Kingdom of\n San d'Oria.\n Forest realm of\n the Elvaan.",
            "Republic of\n Bastok.\n Mines & industry\n of Hume & Galka.",
            "Federation of\n Windurst.\n Magical towers\n & grasslands."
        };
        gfx_draw_string(122, 55, nation_desc[create_nation], COLOR_WHITE, 0, true);
    }

    gfx_draw_string(125, 135, "[A] Next  [B] Back", COLOR_YELLOW, 0, true);
}

/* Zone Exploration Screen */
static void update_zone_explore(void) {
    // Combat auto-attack timer
    if (g_player.in_combat) {
        g_player.weapon_delay_timer++;
        if (g_player.weapon_delay_timer >= g_player.weapon_delay_max) {
            g_player.weapon_delay_timer = 0;
            combat_execute_attack();
        }
    }

    // Mob AI tick
    combat_mob_tick();

    // Resting regeneration tick
    game_tick_resting();

    // Quick resting toggle (L button)
    if (input_is_pressed(&input, KEY_L)) {
        if (!g_player.in_combat) {
            g_player.resting = !g_player.resting;
            audio_play_sfx(g_player.resting ? SFX_CONFIRM : SFX_CANCEL);
            game_log_add(g_player.resting ? "/heal (Kneeling to rest)" : "Stood up.", COLOR_WHITE);
        }
    }

    // Open Action Menu (Start button)
    if (input_is_pressed(&input, KEY_START)) {
        audio_play_sfx(SFX_CONFIRM);
        g_current_screen = SCREEN_ACTION_MENU;
        menu_cursor = 0;
        return;
    }

    // Target nearest mob or cycle (Select button)
    if (input_is_pressed(&input, KEY_SELECT)) {
        int next_target = (g_player.target_index + 1) % g_mob_count;
        for (int i = 0; i < g_mob_count; i++) {
            int idx = (next_target + i) % g_mob_count;
            if (g_mobs[idx].alive) {
                g_player.target_index = idx;
                audio_play_sfx(SFX_CURSOR);
                break;
            }
        }
    }

    // Disengage or cancel target (B button)
    if (input_is_pressed(&input, KEY_B)) {
        if (g_player.in_combat) {
            combat_disengage();
        } else if (g_player.target_index >= 0) {
            g_player.target_index = -1;
            audio_play_sfx(SFX_CANCEL);
        }
    }

    // Talk / Engage / Attack (A button)
    if (input_is_pressed(&input, KEY_A)) {
        // First check if standing next to an NPC
        bool talked = false;
        for (int i = 0; i < g_npc_count; i++) {
            int dx = g_player.x - g_npcs[i].x;
            int dy = g_player.y - g_npcs[i].y;
            if (dx >= -1 && dx <= 1 && dy >= -1 && dy <= 1) {
                audio_play_sfx(SFX_CONFIRM);
                game_log_add(g_npcs[i].text, COLOR_GOLD);
                talked = true;
                break;
            }
        }

        if (!talked) {
            if (g_player.target_index >= 0 && !g_player.in_combat) {
                combat_engage_target(g_player.target_index);
            } else if (g_player.target_index < 0) {
                // Find nearest alive mob to target
                for (int i = 0; i < g_mob_count; i++) {
                    if (g_mobs[i].alive) {
                        g_player.target_index = i;
                        audio_play_sfx(SFX_CURSOR);
                        break;
                    }
                }
            }
        }
    }

    // Movement (D-Pad) if not resting and not in combat locked
    if (!g_player.resting) {
        int nx = g_player.x;
        int ny = g_player.y;

        if (input_is_down(&input, KEY_UP)) {
            g_player.dir = 1;
            if (frame_counter % 6 == 0 && ny > 2) ny--;
        } else if (input_is_down(&input, KEY_DOWN)) {
            g_player.dir = 0;
            if (frame_counter % 6 == 0 && ny < 9) ny++;
        } else if (input_is_down(&input, KEY_LEFT)) {
            g_player.dir = 2;
            if (frame_counter % 6 == 0 && nx > 1) nx--;
        } else if (input_is_down(&input, KEY_RIGHT)) {
            g_player.dir = 3;
            if (frame_counter % 6 == 0 && nx < 18) nx++;
        }

        g_player.x = nx;
        g_player.y = ny;

        // Zone Transitions on edge
        if (nx >= 18) {
            if (g_player.zone_id == ZONE_SANDORIA) {
                game_change_zone(ZONE_WEST_RONFAURE, 2, 6);
                game_log_add("Entered West Ronfaure.", COLOR_GREEN);
            } else if (g_player.zone_id == ZONE_WEST_RONFAURE) {
                game_change_zone(ZONE_VALKURM_DUNES, 2, 6);
                game_log_add("Entered Valkurm Dunes.", COLOR_YELLOW);
            } else if (g_player.zone_id == ZONE_VALKURM_DUNES) {
                game_change_zone(ZONE_SELBINA, 2, 6);
                game_log_add("Entered Selbina outpost.", COLOR_CYAN);
            }
        } else if (nx <= 1) {
            if (g_player.zone_id == ZONE_WEST_RONFAURE) {
                game_change_zone(ZONE_SANDORIA, 17, 6);
                game_log_add("Entered Southern San d'Oria.", COLOR_GOLD);
            } else if (g_player.zone_id == ZONE_VALKURM_DUNES) {
                game_change_zone(ZONE_WEST_RONFAURE, 17, 6);
                game_log_add("Entered West Ronfaure.", COLOR_GREEN);
            } else if (g_player.zone_id == ZONE_SELBINA) {
                game_change_zone(ZONE_VALKURM_DUNES, 17, 6);
                game_log_add("Entered Valkurm Dunes.", COLOR_YELLOW);
            }
        }
    }
}

static void draw_zone_explore(void) {
    // 1. Draw Zone Environment (Top 100 pixels)
    u16 ground_color = COLOR_FOREST;
    if (g_player.zone_id == ZONE_SANDORIA || g_player.zone_id == ZONE_BASTOK) {
        ground_color = RGB15(10, 10, 12); // Cobblestone / city floor
    } else if (g_player.zone_id == ZONE_VALKURM_DUNES) {
        ground_color = COLOR_SAND; // Desert beach sand
    }

    gfx_draw_rect(0, 0, 240, 100, ground_color);

    // Environment details (paths, trees, zone lines)
    if (g_player.zone_id == ZONE_SANDORIA) {
        gfx_draw_rect(0, 0, 240, 16, RGB15(16, 14, 12)); // Fortress wall
        gfx_draw_string(8, 4, "Southern San d'Oria [Kingdom]", COLOR_GOLD, 0, true);
    } else if (g_player.zone_id == ZONE_WEST_RONFAURE) {
        // Forest trees
        for (int tx = 10; tx < 230; tx += 40) {
            gfx_draw_rect(tx, 10, 12, 16, RGB15(2, 10, 2));
            gfx_draw_rect(tx + 4, 26, 4, 6, RGB15(12, 8, 4));
        }
        gfx_draw_string(8, 4, "West Ronfaure [Forest]", COLOR_GREEN, 0, true);
    } else if (g_player.zone_id == ZONE_VALKURM_DUNES) {
        // Ocean water at top
        gfx_draw_rect(0, 0, 240, 22, RGB15(4, 12, 28));
        gfx_draw_string(8, 4, "Valkurm Dunes [Beach]", COLOR_CYAN, 0, true);
    } else if (g_player.zone_id == ZONE_SELBINA) {
        gfx_draw_rect(0, 0, 240, 18, RGB15(18, 16, 12));
        gfx_draw_string(8, 4, "Selbina [Port]", COLOR_YELLOW, 0, true);
    }

    // Draw NPCs
    for (int i = 0; i < g_npc_count; i++) {
        int px = g_npcs[i].x * 12;
        int py = g_npcs[i].y * 8 + 10;
        gfx_draw_player_sprite(px, py, RACE_HUME, JOB_RED_MAGE, 0, 0);
        gfx_draw_string(px - 10, py - 8, g_npcs[i].name, COLOR_GOLD, 0, true);
    }

    // Draw Mobs
    for (int i = 0; i < g_mob_count; i++) {
        if (!g_mobs[i].alive) continue;
        int mx = g_mobs[i].x * 12;
        int my = g_mobs[i].y * 8 + 10;
        gfx_draw_mob_sprite(mx, my, g_mobs[i].type, 0, (frame_counter / 20) % 2);

        // Highlight selected target with cursor bracket
        if (g_player.target_index == i) {
            gfx_draw_rect_outline(mx - 2, my - 2, 20, 20, COLOR_YELLOW);
            // Target Name & HP above mob
            gfx_draw_string(mx - 15, my - 9, g_mobs[i].name, COLOR_YELLOW, 0, true);
        }
    }

    // Draw Player
    int px = g_player.x * 12;
    int py = g_player.y * 8 + 10;
    int anim = (input_is_down(&input, KEY_UP | KEY_DOWN | KEY_LEFT | KEY_RIGHT)) ? ((frame_counter / 10) % 2) : 0;
    gfx_draw_player_sprite(px, py, g_player.race, g_player.job, g_player.dir, anim);

    if (g_player.resting) {
        gfx_draw_string(px - 4, py - 8, "/heal", COLOR_CYAN, 0, true);
    }

    // 2. Draw Bottom Window & HUD (y: 100 to 160)
    gfx_draw_window(0, 100, 240, 60, 0);

    // Left HUD: Player Name, Level, HP, MP, TP Gauges
    gfx_draw_string(6, 104, g_player.name, COLOR_WHITE, 0, true);
    char lvl_buf[8];
    lvl_buf[0] = 'L'; lvl_buf[1] = 'v';
    lvl_buf[2] = '0' + (g_player.level / 10);
    lvl_buf[3] = '0' + (g_player.level % 10);
    lvl_buf[4] = '\0';
    gfx_draw_string(52, 104, lvl_buf, COLOR_GOLD, 0, true);

    // HP Bar
    gfx_draw_string(6, 116, "HP", COLOR_WHITE, 0, true);
    gfx_draw_gauge(22, 117, 50, 7, g_player.hp, g_player.max_hp, COLOR_GREEN, RGB15(6, 12, 6));

    // MP Bar
    gfx_draw_string(6, 128, "MP", COLOR_WHITE, 0, true);
    gfx_draw_gauge(22, 129, 50, 7, g_player.mp, (g_player.max_mp > 0 ? g_player.max_mp : 1), COLOR_CYAN, RGB15(4, 8, 16));

    // TP Bar
    gfx_draw_string(6, 140, "TP", COLOR_WHITE, 0, true);
    gfx_draw_gauge(22, 141, 50, 7, g_player.tp, 3000, (g_player.tp >= 1000) ? COLOR_GOLD : COLOR_BLUE, RGB15(4, 6, 10));

    // Divider line
    gfx_draw_vline(78, 102, 56, RGB15(14, 14, 18));

    // Right Side: Live Combat & Dialogue Log (3 lines)
    int log_y = 104;
    for (int i = 0; i < 4; i++) {
        int idx = (g_log.head + MAX_COMBAT_LOGS - 4 + i) % MAX_COMBAT_LOGS;
        if (g_log.lines[idx][0] != '\0') {
            gfx_draw_string(84, log_y, g_log.lines[idx], g_log.colors[idx], 0, true);
            log_y += 12;
        }
    }

    // Engagement alert
    if (g_player.in_combat) {
        gfx_draw_string(180, 102, "[BATTLE]", COLOR_RED, 0, true);
    }
}

/* Action Menu Screen */
static void update_action_menu(void) {
    if (input_is_pressed(&input, KEY_DOWN)) {
        menu_cursor = (menu_cursor + 1) % 6;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_UP)) {
        menu_cursor = (menu_cursor + 5) % 6;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_B) || input_is_pressed(&input, KEY_START)) {
        audio_play_sfx(SFX_CANCEL);
        g_current_screen = SCREEN_ZONE_EXPLORE;
        return;
    }
    if (input_is_pressed(&input, KEY_A)) {
        audio_play_sfx(SFX_CONFIRM);
        if (menu_cursor == 0) { // Status
            g_current_screen = SCREEN_STATUS_MENU;
        } else if (menu_cursor == 1) { // Weapon Skill
            g_current_screen = SCREEN_WS_MENU;
            menu_cursor = 0;
        } else if (menu_cursor == 2) { // Magic
            g_current_screen = SCREEN_MAGIC_MENU;
            menu_cursor = 0;
        } else if (menu_cursor == 3) { // Rest /heal
            g_player.resting = !g_player.resting;
            game_log_add(g_player.resting ? "Kneeling to rest." : "Stood up.", COLOR_WHITE);
            g_current_screen = SCREEN_ZONE_EXPLORE;
        } else if (menu_cursor == 4) { // Save SRAM
            save_game_to_sram();
            g_current_screen = SCREEN_ZONE_EXPLORE;
        } else if (menu_cursor == 5) { // Return Title
            g_current_screen = SCREEN_TITLE;
            menu_cursor = 0;
            audio_play_bgm(BGM_TITLE_THEME);
        }
    }
}

static void draw_action_menu(void) {
    draw_zone_explore(); // Draw background behind menu

    gfx_draw_window(70, 20, 105, 96, "Action Menu");

    const char* opts[] = {
        "Status",
        "Weapon Skills",
        "Magic / Spells",
        "Rest (/heal)",
        "Save Game",
        "Title Screen"
    };

    for (int i = 0; i < 6; i++) {
        u16 col = (menu_cursor == i) ? COLOR_GOLD : COLOR_WHITE;
        gfx_draw_string(88, 36 + (i * 12), opts[i], col, 0, true);
    }
    gfx_draw_string(76, 36 + (menu_cursor * 12), ">", COLOR_GOLD, 0, true);
}

/* Status Menu Screen */
static void update_status_menu(void) {
    if (input_is_pressed(&input, KEY_B) || input_is_pressed(&input, KEY_A)) {
        audio_play_sfx(SFX_CANCEL);
        g_current_screen = SCREEN_ACTION_MENU;
    }
}

static void draw_status_menu(void) {
    gfx_clear(RGB15(2, 3, 6));

    gfx_draw_window(10, 10, 220, 140, "Player Status");

    gfx_draw_player_sprite(25, 30, g_player.race, g_player.job, 0, 0);
    gfx_draw_string(50, 30, g_player.name, COLOR_GOLD, 0, true);

    const char* job_names[] = {"Warrior", "Monk", "White Mage", "Black Mage", "Red Mage", "Thief"};
    gfx_draw_string(50, 42, job_names[g_player.job], COLOR_WHITE, 0, true);

    char buf[36];
    // Level & Gil
    gfx_draw_string(50, 54, "Gil:", COLOR_YELLOW, 0, true);
    buf[0] = '5'; buf[1] = '0'; buf[2] = '0'; buf[3] = '\0';
    gfx_draw_string(80, 54, buf, COLOR_WHITE, 0, true);

    // Attributes list
    gfx_draw_subwindow(20, 70, 200, 70);
    gfx_draw_string(30, 78, "STR:", COLOR_CYAN, 0, true);
    gfx_draw_string(30, 90, "DEX:", COLOR_CYAN, 0, true);
    gfx_draw_string(30, 102, "VIT:", COLOR_CYAN, 0, true);
    gfx_draw_string(30, 114, "AGI:", COLOR_CYAN, 0, true);

    gfx_draw_string(120, 78, "INT:", COLOR_CYAN, 0, true);
    gfx_draw_string(120, 90, "MND:", COLOR_CYAN, 0, true);
    gfx_draw_string(120, 102, "ATK:", COLOR_CYAN, 0, true);
    gfx_draw_string(120, 114, "DEF:", COLOR_CYAN, 0, true);

    gfx_draw_string(140, 130, "[B] Back", COLOR_GOLD, 0, true);
}

/* Weapon Skill Menu Screen */
static void update_ws_menu(void) {
    if (input_is_pressed(&input, KEY_DOWN)) {
        menu_cursor = (menu_cursor + 1) % 4;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_UP)) {
        menu_cursor = (menu_cursor + 3) % 4;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_B)) {
        audio_play_sfx(SFX_CANCEL);
        g_current_screen = SCREEN_ACTION_MENU;
        return;
    }
    if (input_is_pressed(&input, KEY_A)) {
        combat_execute_ws(menu_cursor);
        g_current_screen = SCREEN_ZONE_EXPLORE;
    }
}

static void draw_ws_menu(void) {
    draw_zone_explore();
    gfx_draw_window(60, 25, 120, 75, "Weapon Skills");
    const char* ws[] = {
        "Fast Blade (1000)",
        "Combo      (1000)",
        "Red Lotus  (1000)",
        "Viper Bite (1000)"
    };
    for (int i = 0; i < 4; i++) {
        u16 col = (menu_cursor == i) ? COLOR_GOLD : (g_player.tp >= 1000 ? COLOR_WHITE : COLOR_GRAY);
        gfx_draw_string(76, 40 + (i * 12), ws[i], col, 0, true);
    }
    gfx_draw_string(66, 40 + (menu_cursor * 12), ">", COLOR_GOLD, 0, true);
}

/* Magic Menu Screen */
static void update_magic_menu(void) {
    if (input_is_pressed(&input, KEY_DOWN)) {
        menu_cursor = (menu_cursor + 1) % 2;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_UP)) {
        menu_cursor = (menu_cursor + 1) % 2;
        audio_play_sfx(SFX_CURSOR);
    }
    if (input_is_pressed(&input, KEY_B)) {
        audio_play_sfx(SFX_CANCEL);
        g_current_screen = SCREEN_ACTION_MENU;
        return;
    }
    if (input_is_pressed(&input, KEY_A)) {
        combat_cast_spell(menu_cursor);
        g_current_screen = SCREEN_ZONE_EXPLORE;
    }
}

static void draw_magic_menu(void) {
    draw_zone_explore();
    gfx_draw_window(60, 30, 120, 60, "Magic");
    const char* spells[] = {
        "Cure    (8 MP)",
        "Stone   (9 MP)"
    };
    for (int i = 0; i < 2; i++) {
        u16 col = (menu_cursor == i) ? COLOR_GOLD : COLOR_WHITE;
        gfx_draw_string(76, 45 + (i * 14), spells[i], col, 0, true);
    }
    gfx_draw_string(66, 45 + (menu_cursor * 14), ">", COLOR_GOLD, 0, true);
}

/* Game Over Screen */
static void update_game_over(void) {
    if (input_is_pressed(&input, KEY_START) || input_is_pressed(&input, KEY_A)) {
        audio_play_sfx(SFX_CONFIRM);
        // Revive at starting nation with half HP
        g_player.hp = g_player.max_hp / 2;
        g_player.in_combat = false;
        game_change_zone(ZONE_SANDORIA, 10, 8);
        game_log_add("Revived at Home Point.", COLOR_GOLD);
        g_current_screen = SCREEN_ZONE_EXPLORE;
    }
}

static void draw_game_over(void) {
    gfx_clear(RGB15(6, 1, 1));
    gfx_draw_window(30, 40, 180, 70, 0);
    gfx_draw_string_shadow(55, 55, "You have been defeated...", COLOR_RED);
    gfx_draw_string(45, 80, "Press START to return Home", COLOR_WHITE, 0, true);
}

/* Main Entry Point */
int main(void) {
    gfx_init();
    audio_init();
    game_init_defaults();
    audio_play_bgm(BGM_TITLE_THEME);

    while (1) {
        // Wait for vertical blank (60 Hz synchronization)
        gba_wait_vblank();
        frame_counter++;

        // Update controllers and input
        input_update(&input);

        // Update audio sequencer
        audio_update();

        // Screen State Update & Draw
        switch (g_current_screen) {
            case SCREEN_TITLE:
                update_title_screen();
                draw_title_screen();
                break;
            case SCREEN_CHAR_CREATE:
                update_char_create();
                draw_char_create();
                break;
            case SCREEN_ZONE_EXPLORE:
                update_zone_explore();
                draw_zone_explore();
                break;
            case SCREEN_ACTION_MENU:
                update_action_menu();
                draw_action_menu();
                break;
            case SCREEN_STATUS_MENU:
                update_status_menu();
                draw_status_menu();
                break;
            case SCREEN_WS_MENU:
                update_ws_menu();
                draw_ws_menu();
                break;
            case SCREEN_MAGIC_MENU:
                update_magic_menu();
                draw_magic_menu();
                break;
            case SCREEN_GAME_OVER:
                update_game_over();
                draw_game_over();
                break;
            default:
                g_current_screen = SCREEN_TITLE;
                break;
        }
    }

    return 0;
}
