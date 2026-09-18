/*
 * FFXI Advance - Game State, Combat, and World Definitions
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#ifndef GAME_STATE_H
#define GAME_STATE_H

#include "gba.h"

#define MAX_INVENTORY_SLOTS 20
#define MAX_ZONE_MOBS       12
#define MAX_ZONE_NPCS       8
#define MAX_COMBAT_LOGS     4

typedef enum {
    RACE_HUME = 0,
    RACE_ELVAAN,
    RACE_TARUTARU,
    RACE_MITHRA,
    RACE_GALKA,
    RACE_COUNT
} PlayerRace;

typedef enum {
    JOB_WARRIOR = 0,    // WAR
    JOB_MONK,           // MNK
    JOB_WHITE_MAGE,     // WHM
    JOB_BLACK_MAGE,     // BLM
    JOB_RED_MAGE,       // RDM
    JOB_THIEF,          // THF
    JOB_COUNT
} PlayerJob;

typedef enum {
    NATION_SANDORIA = 0,
    NATION_BASTOK,
    NATION_WINDURST,
    NATION_COUNT
} Nation;

typedef enum {
    ZONE_SANDORIA = 0,
    ZONE_WEST_RONFAURE,
    ZONE_BASTOK,
    ZONE_SOUTH_GUSTABERG,
    ZONE_WINDURST,
    ZONE_WEST_SARUTABARUTA,
    ZONE_VALKURM_DUNES,
    ZONE_SELBINA,
    ZONE_COUNT
} ZoneID;

typedef enum {
    MOB_WILD_RABBIT = 0,
    MOB_FOREST_FUNGUAR,
    MOB_MANDRAGORA,
    MOB_GOBLIN_THUG,
    MOB_DAMSELFLY,
    MOB_CARRION_WORM,
    MOB_QUADAV,
    MOB_ORC_ORANGE,
    MOB_TYPE_COUNT
} MobType;

typedef struct {
    u16 item_id;
    u8  quantity;
} InventorySlot;

typedef struct {
    char name[16];
    MobType type;
    u8   level;
    s16  hp;
    s16  max_hp;
    u16  attack;
    u16  defense;
    u16  exp_reward;
    u16  gil_reward;
    u8   x;
    u8   y;
    bool alive;
    u16  respawn_timer;
    u8   attack_timer;
} Monster;

typedef struct {
    char name[16];
    u8   x;
    u8   y;
    u8   dialogue_id;
    const char* text;
} NPC;

typedef struct {
    char name[16];
    u8   race;
    u8   job;
    u8   subjob;
    u8   nation;
    u8   level;
    u32  exp;
    u32  exp_to_next;
    s16  hp;
    s16  max_hp;
    s16  mp;
    s16  max_mp;
    s16  tp;             // Tactical Points 0 - 3000
    u32  gil;

    /* Base Attributes */
    u16  str;
    u16  dex;
    u16  vit;
    u16  agi;
    u16  int_;
    u16  mnd;
    u16  chr;
    u16  attack;
    u16  defense;

    /* World Position */
    u8   zone_id;
    u8   x;
    u8   y;
    u8   dir;           // 0: Down, 1: Up, 2: Left, 3: Right
    bool resting;       // /heal kneeling state
    u8   rest_timer;

    /* Combat State */
    bool in_combat;
    int  target_index;
    u8   weapon_delay_timer;
    u8   weapon_delay_max;

    /* Quest Progress Flags */
    bool rank_mission_active;
    bool rank_mission_done;
    bool signet_active;
    bool subjob_quest_active;
    bool subjob_quest_done;

    /* Inventory */
    InventorySlot inventory[MAX_INVENTORY_SLOTS];
} PlayerState;

typedef struct {
    char lines[MAX_COMBAT_LOGS][36];
    u16  colors[MAX_COMBAT_LOGS];
    u8   head;
} CombatLog;

typedef enum {
    SCREEN_TITLE = 0,
    SCREEN_CHAR_CREATE,
    SCREEN_ZONE_EXPLORE,
    SCREEN_STATUS_MENU,
    SCREEN_ACTION_MENU,
    SCREEN_MAGIC_MENU,
    SCREEN_WS_MENU,
    SCREEN_DIALOGUE,
    SCREEN_GAME_OVER
} GameScreen;

/* Global state pointers */
extern PlayerState g_player;
extern CombatLog   g_log;
extern Monster     g_mobs[MAX_ZONE_MOBS];
extern int         g_mob_count;
extern NPC         g_npcs[MAX_ZONE_NPCS];
extern int         g_npc_count;
extern GameScreen  g_current_screen;

/* Core functions */
void game_init_defaults(void);
void game_start_new(const char* name, int race, int job, int nation);
void game_log_add(const char* msg, u16 color);
void game_change_zone(ZoneID new_zone, int spawn_x, int spawn_y);
void game_tick_resting(void);
void game_check_level_up(void);

/* Combat actions */
void combat_engage_target(int mob_index);
void combat_disengage(void);
void combat_execute_attack(void);
void combat_execute_ws(int ws_id);
void combat_cast_spell(int spell_id);
void combat_mob_tick(void);

/* Save / Load SRAM */
bool save_game_to_sram(void);
bool load_game_from_sram(void);
bool has_valid_save_in_sram(void);

#endif /* GAME_STATE_H */
