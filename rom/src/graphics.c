/*
 * FFXI Advance - Graphics Engine Implementation
 * Mode 3 Direct Color (240x160 RGB555)
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#include "graphics.h"

/* Standard 8x8 bitmap font (ASCII 32 ' ' to 126 '~') */
static const u8 font_8x8[95][8] = {
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}, // 32 ' '
    {0x18,0x3C,0x3C,0x18,0x18,0x00,0x18,0x00}, // 33 '!'
    {0x66,0x66,0x24,0x00,0x00,0x00,0x00,0x00}, // 34 '"'
    {0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00}, // 35 '#'
    {0x18,0x3E,0x60,0x3C,0x06,0x7C,0x18,0x00}, // 36 '$'
    {0x00,0xC6,0xCC,0x18,0x30,0x66,0xC6,0x00}, // 37 '%'
    {0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00}, // 38 '&'
    {0x30,0x30,0x10,0x20,0x00,0x00,0x00,0x00}, // 39 '''
    {0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00}, // 40 '('
    {0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00}, // 41 ')'
    {0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00}, // 42 '*'
    {0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00}, // 43 '+'
    {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30}, // 44 ','
    {0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00}, // 45 '-'
    {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00}, // 46 '.'
    {0x06,0x0C,0x18,0x30,0x60,0xC0,0x80,0x00}, // 47 '/'
    {0x3C,0x66,0xC3,0xC3,0xC3,0x66,0x3C,0x00}, // 48 '0'
    {0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00}, // 49 '1'
    {0x7C,0xC6,0x0E,0x3C,0x70,0xE0,0xFE,0x00}, // 50 '2'
    {0x7E,0x0C,0x18,0x3C,0x06,0xC6,0x7C,0x00}, // 51 '3'
    {0x1C,0x3C,0x6C,0xCC,0xFE,0x0C,0x1E,0x00}, // 52 '4'
    {0xFE,0xC0,0xFC,0x06,0x06,0xC6,0x7C,0x00}, // 53 '5'
    {0x38,0x60,0xC0,0xFC,0xC6,0xC6,0x7C,0x00}, // 54 '6'
    {0xFE,0xC6,0x0C,0x18,0x30,0x30,0x30,0x00}, // 55 '7'
    {0x7C,0xC6,0xC6,0x7C,0xC6,0xC6,0x7C,0x00}, // 56 '8'
    {0x7C,0xC6,0xC6,0x7E,0x06,0x0C,0x78,0x00}, // 57 '9'
    {0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00}, // 58 ':'
    {0x00,0x18,0x18,0x00,0x18,0x18,0x30,0x00}, // 59 ';'
    {0x0E,0x1C,0x38,0x70,0x38,0x1C,0x0E,0x00}, // 60 '<'
    {0x00,0x7E,0x00,0x7E,0x00,0x00,0x00,0x00}, // 61 '='
    {0x70,0x38,0x1C,0x0E,0x1C,0x38,0x70,0x00}, // 62 '>'
    {0x7C,0xC6,0x0C,0x18,0x18,0x00,0x18,0x00}, // 63 '?'
    {0x7C,0xC6,0xDE,0xD6,0xD6,0xC0,0x7C,0x00}, // 64 '@'
    {0x38,0x6C,0xC6,0xC6,0xFE,0xC6,0xC6,0x00}, // 65 'A'
    {0xFC,0x66,0x66,0x7C,0x66,0x66,0xFC,0x00}, // 66 'B'
    {0x3C,0x66,0xC0,0xC0,0xC0,0x66,0x3C,0x00}, // 67 'C'
    {0xF8,0x6C,0x66,0x66,0x66,0x6C,0xF8,0x00}, // 68 'D'
    {0xFE,0x62,0x68,0x78,0x68,0x62,0xFE,0x00}, // 69 'E'
    {0xFE,0x62,0x68,0x78,0x68,0x60,0xF0,0x00}, // 70 'F'
    {0x3C,0x66,0xC0,0xC0,0xCE,0x66,0x3E,0x00}, // 71 'G'
    {0xC6,0xC6,0xC6,0xFE,0xC6,0xC6,0xC6,0x00}, // 72 'H'
    {0x7E,0x18,0x18,0x18,0x18,0x18,0x7E,0x00}, // 73 'I'
    {0x1E,0x06,0x06,0x06,0xC6,0xC6,0x7C,0x00}, // 74 'J'
    {0xC6,0xCC,0xD8,0xF0,0xD8,0xCC,0xC6,0x00}, // 75 'K'
    {0xE0,0x60,0x60,0x60,0x62,0x66,0xFE,0x00}, // 76 'L'
    {0xC3,0xE7,0xFF,0xDB,0xC3,0xC3,0xC3,0x00}, // 77 'M'
    {0xC6,0xE6,0xF6,0xDE,0xCE,0xC6,0xC6,0x00}, // 78 'N'
    {0x7C,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00}, // 79 'O'
    {0xFC,0x66,0x66,0x7C,0x60,0x60,0xF0,0x00}, // 80 'P'
    {0x7C,0xC6,0xC6,0xC6,0xD6,0xCC,0x76,0x00}, // 81 'Q'
    {0xFC,0x66,0x66,0x7C,0xD8,0xCC,0xC6,0x00}, // 82 'R'
    {0x7C,0xC6,0x60,0x38,0x0C,0xC6,0x7C,0x00}, // 83 'S'
    {0x7E,0x5A,0x18,0x18,0x18,0x18,0x3C,0x00}, // 84 'T'
    {0xC6,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00}, // 85 'U'
    {0xC6,0xC6,0xC6,0xC6,0x6C,0x38,0x10,0x00}, // 86 'V'
    {0xC3,0xC3,0xC3,0xDB,0xFF,0xE7,0xC3,0x00}, // 87 'W'
    {0xC3,0x66,0x3C,0x18,0x3C,0x66,0xC3,0x00}, // 88 'X'
    {0xC3,0xC3,0x66,0x3C,0x18,0x18,0x3C,0x00}, // 89 'Y'
    {0xFF,0xC3,0x0C,0x18,0x30,0x61,0xFF,0x00}, // 90 'Z'
    {0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00}, // 91 '['
    {0xC0,0x60,0x30,0x18,0x0C,0x06,0x02,0x00}, // 92 '\'
    {0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00}, // 93 ']'
    {0x18,0x3C,0x66,0x00,0x00,0x00,0x00,0x00}, // 94 '^'
    {0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0x00}, // 95 '_'
    {0x30,0x18,0x0C,0x00,0x00,0x00,0x00,0x00}, // 96 '`'
    {0x00,0x00,0x78,0x0C,0x7C,0xCC,0x76,0x00}, // 97 'a'
    {0xE0,0x60,0x7C,0x66,0x66,0x66,0xDC,0x00}, // 98 'b'
    {0x00,0x00,0x7C,0xC6,0xC0,0xC6,0x7C,0x00}, // 99 'c'
    {0x1C,0x0C,0x7C,0xCC,0xCC,0xCC,0x76,0x00}, // 100 'd'
    {0x00,0x00,0x7C,0xC6,0xFE,0xC0,0x7C,0x00}, // 101 'e'
    {0x38,0x6C,0x64,0xF0,0x60,0x60,0xF0,0x00}, // 102 'f'
    {0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0xF8}, // 103 'g'
    {0xE0,0x60,0x6C,0x76,0x66,0x66,0xE6,0x00}, // 104 'h'
    {0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00}, // 105 'i'
    {0x06,0x00,0x0E,0x06,0x06,0x66,0x66,0x3C}, // 106 'j'
    {0xE0,0x60,0x66,0x6C,0x78,0x6C,0xE6,0x00}, // 107 'k'
    {0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00}, // 108 'l'
    {0x00,0x00,0xEC,0xFE,0xD6,0xD6,0xD6,0x00}, // 109 'm'
    {0x00,0x00,0xDC,0x66,0x66,0x66,0x66,0x00}, // 110 'n'
    {0x00,0x00,0x7C,0xC6,0xC6,0xC6,0x7C,0x00}, // 111 'o'
    {0x00,0x00,0xDC,0x66,0x66,0x7C,0x60,0xF0}, // 112 'p'
    {0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0x1E}, // 113 'q'
    {0x00,0x00,0xDC,0x76,0x60,0x60,0xF0,0x00}, // 114 'r'
    {0x00,0x00,0x7C,0xC0,0x78,0x0E,0xFC,0x00}, // 115 's'
    {0x30,0x30,0xFC,0x30,0x30,0x34,0x18,0x00}, // 116 't'
    {0x00,0x00,0xCC,0xCC,0xCC,0xCC,0x76,0x00}, // 117 'u'
    {0x00,0x00,0xC6,0xC6,0x6C,0x38,0x10,0x00}, // 118 'v'
    {0x00,0x00,0xC6,0xD6,0xD6,0xFE,0x6C,0x00}, // 119 'w'
    {0x00,0x00,0xC6,0x6C,0x38,0x6C,0xC6,0x00}, // 120 'x'
    {0x00,0x00,0xC6,0xC6,0xC6,0x7E,0x06,0xFC}, // 121 'y'
    {0x00,0x00,0xFE,0x8C,0x18,0x32,0xFE,0x00}, // 122 'z'
    {0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00}, // 123 '{'
    {0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00}, // 124 '|'
    {0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00}, // 125 '}'
    {0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00}, // 126 '~'
};

void gfx_init(void) {
    /* Set GBA Video Mode 3 (240x160 15-bit color) + BG2 */
    REG_DISPCNT = MODE_3 | BG2_ENABLE;
}

void gfx_clear(u16 color) {
    u32 dword_color = color | (color << 16);
    vu32* vram32 = (vu32*)MEM_VRAM;
    for (int i = 0; i < (SCREEN_WIDTH * SCREEN_HEIGHT) / 2; i++) {
        vram32[i] = dword_color;
    }
}

void gfx_draw_pixel(int x, int y, u16 color) {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        MEM_VRAM[y * SCREEN_WIDTH + x] = color;
    }
}

void gfx_draw_rect(int x, int y, int w, int h, u16 color) {
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > SCREEN_WIDTH)  w = SCREEN_WIDTH - x;
    if (y + h > SCREEN_HEIGHT) h = SCREEN_HEIGHT - y;
    if (w <= 0 || h <= 0) return;

    for (int j = 0; j < h; j++) {
        vu16* row = &MEM_VRAM[(y + j) * SCREEN_WIDTH + x];
        for (int i = 0; i < w; i++) {
            row[i] = color;
        }
    }
}

void gfx_draw_rect_outline(int x, int y, int w, int h, u16 color) {
    gfx_draw_hline(x, y, w, color);
    gfx_draw_hline(x, y + h - 1, w, color);
    gfx_draw_vline(x, y, h, color);
    gfx_draw_vline(x + w - 1, y, h, color);
}

void gfx_draw_hline(int x, int y, int length, u16 color) {
    if (y < 0 || y >= SCREEN_HEIGHT) return;
    int start = (x < 0) ? 0 : x;
    int end = (x + length > SCREEN_WIDTH) ? SCREEN_WIDTH : (x + length);
    vu16* row = &MEM_VRAM[y * SCREEN_WIDTH];
    for (int i = start; i < end; i++) {
        row[i] = color;
    }
}

void gfx_draw_vline(int x, int y, int length, u16 color) {
    if (x < 0 || x >= SCREEN_WIDTH) return;
    int start = (y < 0) ? 0 : y;
    int end = (y + length > SCREEN_HEIGHT) ? SCREEN_HEIGHT : (y + length);
    for (int j = start; j < end; j++) {
        MEM_VRAM[j * SCREEN_WIDTH + x] = color;
    }
}

/* FFXI Classic Window Styling */
void gfx_draw_window(int x, int y, int w, int h, const char* title) {
    // Drop shadow
    gfx_draw_rect(x + 2, y + 2, w, h, RGB15(1, 1, 3));

    // Outer border (Gold/Silver metallic)
    gfx_draw_rect_outline(x, y, w, h, RGB15(26, 24, 16));
    gfx_draw_rect_outline(x + 1, y + 1, w - 2, h - 2, RGB15(12, 11, 8));

    // Marble blue gradient fill
    for (int j = 2; j < h - 2; j++) {
        int py = y + j;
        if (py < 0 || py >= SCREEN_HEIGHT) continue;
        
        // Slight gradient from deep royal blue to dark navy
        u8 b = 10 + ((j * 6) / h);
        u8 r = 1 + (j / 16);
        u8 g = 3 + (j / 10);
        u16 bg_blue = RGB15(r, g, b);

        vu16* row = &MEM_VRAM[py * SCREEN_WIDTH];
        for (int i = 2; i < w - 2; i++) {
            int px = x + i;
            if (px >= 0 && px < SCREEN_WIDTH) {
                row[px] = bg_blue;
            }
        }
    }

    // Optional Title bar
    if (title && title[0] != '\0') {
        gfx_draw_rect(x + 2, y + 2, w - 4, 11, RGB15(4, 7, 18));
        gfx_draw_hline(x + 2, y + 13, w - 4, RGB15(18, 17, 12));
        gfx_draw_string(x + 5, y + 4, title, COLOR_GOLD, 0, true);
    }
}

void gfx_draw_subwindow(int x, int y, int w, int h) {
    gfx_draw_rect_outline(x, y, w, h, RGB15(16, 16, 20));
    for (int j = 1; j < h - 1; j++) {
        int py = y + j;
        if (py < 0 || py >= SCREEN_HEIGHT) continue;
        vu16* row = &MEM_VRAM[py * SCREEN_WIDTH];
        for (int i = 1; i < w - 1; i++) {
            int px = x + i;
            if (px >= 0 && px < SCREEN_WIDTH) {
                row[px] = RGB15(2, 4, 10);
            }
        }
    }
}

void gfx_draw_char(int x, int y, char c, u16 color, u16 bg_color, bool transparent_bg) {
    if (c < 32 || c > 126) c = ' ';
    const u8* glyph = font_8x8[c - 32];

    for (int row = 0; row < 8; row++) {
        int py = y + row;
        if (py < 0 || py >= SCREEN_HEIGHT) continue;
        u8 bits = glyph[row];
        for (int col = 0; col < 8; col++) {
            int px = x + col;
            if (px < 0 || px >= SCREEN_WIDTH) continue;
            if (bits & (0x80 >> col)) {
                MEM_VRAM[py * SCREEN_WIDTH + px] = color;
            } else if (!transparent_bg) {
                MEM_VRAM[py * SCREEN_WIDTH + px] = bg_color;
            }
        }
    }
}

void gfx_draw_string(int x, int y, const char* str, u16 color, u16 bg_color, bool transparent_bg) {
    if (!str) return;
    int cur_x = x;
    int cur_y = y;
    while (*str) {
        if (*str == '\n') {
            cur_x = x;
            cur_y += 9;
        } else {
            gfx_draw_char(cur_x, cur_y, *str, color, bg_color, transparent_bg);
            cur_x += 7; // Slightly proportional kerning
        }
        str++;
    }
}

void gfx_draw_string_shadow(int x, int y, const char* str, u16 color) {
    gfx_draw_string(x + 1, y + 1, str, COLOR_BLACK, 0, true);
    gfx_draw_string(x, y, str, color, 0, true);
}

void gfx_draw_gauge(int x, int y, int w, int h, int current, int max, u16 fill_color, u16 bg_color) {
    if (max <= 0) max = 1;
    if (current < 0) current = 0;
    if (current > max) current = max;

    int fill_w = ((w - 2) * current) / max;

    // Background border & trough
    gfx_draw_rect_outline(x, y, w, h, RGB15(10, 10, 10));
    gfx_draw_rect(x + 1, y + 1, w - 2, h - 2, bg_color);

    // Filled portion with top gloss line
    if (fill_w > 0) {
        gfx_draw_rect(x + 1, y + 1, fill_w, h - 2, fill_color);
        // Bright highlight on top line
        u16 highlight = fill_color | RGB15(8, 8, 8);
        gfx_draw_hline(x + 1, y + 1, fill_w, highlight);
    }
}

/* 16x16 Player and NPC Sprites */
void gfx_draw_player_sprite(int x, int y, int race, int job, int dir, int anim_frame) {
    // Primary color palette depending on job
    u16 armor_color = RGB15(14, 14, 18); // Warrior iron
    u16 sub_color   = RGB15(20, 6, 6);   // Red trim
    u16 skin_color  = RGB15(30, 24, 19);

    if (job == 1) { // Monk (Gi / martial)
        armor_color = RGB15(25, 14, 6);
        sub_color   = RGB15(28, 26, 12);
    } else if (job == 2) { // White Mage (White/Red robes)
        armor_color = RGB15(30, 30, 30);
        sub_color   = RGB15(28, 4, 4);
    } else if (job == 3) { // Black Mage (Tunic / wizard hat)
        armor_color = RGB15(6, 6, 20);
        sub_color   = RGB15(26, 24, 6);
    } else if (job == 4) { // Red Mage (Crimson duelist)
        armor_color = RGB15(28, 4, 4);
        sub_color   = RGB15(30, 30, 30);
    } else if (job == 5) { // Thief (Leather jerkin)
        armor_color = RGB15(16, 12, 6);
        sub_color   = RGB15(8, 18, 10);
    }

    // Walking bounce
    int bob = (anim_frame % 2);

    // Head / Helm
    gfx_draw_rect(x + 5, y + 2 - bob, 6, 5, skin_color);
    gfx_draw_rect(x + 4, y + 1 - bob, 8, 3, armor_color); // Hair/Helm

    // Eyes
    if (dir == 0) { // Down
        gfx_draw_pixel(x + 6, y + 4 - bob, RGB15(4, 4, 12));
        gfx_draw_pixel(x + 9, y + 4 - bob, RGB15(4, 4, 12));
    } else if (dir == 2) { // Left
        gfx_draw_pixel(x + 5, y + 4 - bob, RGB15(4, 4, 12));
    } else if (dir == 3) { // Right
        gfx_draw_pixel(x + 10, y + 4 - bob, RGB15(4, 4, 12));
    }

    // Torso / Armor
    gfx_draw_rect(x + 4, y + 7 - bob, 8, 5, armor_color);
    gfx_draw_rect(x + 6, y + 8 - bob, 4, 3, sub_color); // Emblem/crest

    // Legs / Boots
    int leg_offset = (anim_frame % 2 == 1) ? 1 : 0;
    gfx_draw_rect(x + 4, y + 12, 3, 4 - leg_offset, RGB15(6, 6, 8));
    gfx_draw_rect(x + 9, y + 12, 3, 4 + leg_offset, RGB15(6, 6, 8));

    // Weapon representation
    if (job == 0 || job == 4) { // Sword
        gfx_draw_vline(x + 13, y + 5 - bob, 8, RGB15(26, 26, 28));
        gfx_draw_pixel(x + 12, y + 9 - bob, COLOR_GOLD);
        gfx_draw_pixel(x + 14, y + 9 - bob, COLOR_GOLD);
    } else if (job == 2 || job == 3) { // Staff
        gfx_draw_vline(x + 13, y + 3 - bob, 12, RGB15(16, 10, 4));
        gfx_draw_pixel(x + 13, y + 2 - bob, COLOR_YELLOW);
    }
}

/* Monster Sprites */
void gfx_draw_mob_sprite(int x, int y, int mob_type, int dir, int anim_frame) {
    int bob = (anim_frame % 2);

    if (mob_type == 0) { // Wild Rabbit (White hare)
        gfx_draw_rect(x + 5, y + 7 - bob, 6, 6, RGB15(30, 30, 30));
        // Ears
        gfx_draw_vline(x + 6, y + 1 - bob, 6, RGB15(30, 30, 30));
        gfx_draw_vline(x + 9, y + 1 - bob, 6, RGB15(30, 30, 30));
        gfx_draw_vline(x + 6, y + 3 - bob, 3, RGB15(31, 20, 20)); // Pink inner
        gfx_draw_vline(x + 9, y + 3 - bob, 3, RGB15(31, 20, 20));
        // Red Eyes
        gfx_draw_pixel(x + 6, y + 8 - bob, COLOR_RED);
        gfx_draw_pixel(x + 9, y + 8 - bob, COLOR_RED);
        // Feet
        gfx_draw_rect(x + 4, y + 13, 3, 2, RGB15(28, 28, 28));
        gfx_draw_rect(x + 9, y + 13, 3, 2, RGB15(28, 28, 28));
    } else if (mob_type == 1) { // Forest Funguar (Mushroom)
        // Mushroom Cap
        gfx_draw_rect(x + 2, y + 2 - bob, 12, 5, RGB15(24, 6, 4));
        gfx_draw_pixel(x + 4, y + 4 - bob, COLOR_WHITE);
        gfx_draw_pixel(x + 9, y + 3 - bob, COLOR_WHITE);
        gfx_draw_pixel(x + 11, y + 5 - bob, COLOR_WHITE);
        // Stem / Body
        gfx_draw_rect(x + 5, y + 7 - bob, 6, 7, RGB15(26, 25, 20));
        // Beady eyes
        gfx_draw_pixel(x + 6, y + 9 - bob, COLOR_BLACK);
        gfx_draw_pixel(x + 9, y + 9 - bob, COLOR_BLACK);
    } else if (mob_type == 2) { // Mandragora (Iconic onion mascot)
        // Green leaves on head
        gfx_draw_rect(x + 6, y + 1 - bob, 4, 4, COLOR_GREEN);
        gfx_draw_pixel(x + 4, y + 2 - bob, RGB15(10, 26, 10));
        gfx_draw_pixel(x + 11, y + 2 - bob, RGB15(10, 26, 10));
        // Round yellow-white body
        gfx_draw_rect(x + 4, y + 5 - bob, 8, 7, RGB15(30, 29, 22));
        // Cute black eyes
        gfx_draw_pixel(x + 6, y + 7 - bob, COLOR_BLACK);
        gfx_draw_pixel(x + 9, y + 7 - bob, COLOR_BLACK);
        // Pink cheeks
        gfx_draw_pixel(x + 5, y + 9 - bob, RGB15(31, 16, 18));
        gfx_draw_pixel(x + 10, y + 9 - bob, RGB15(31, 16, 18));
        // Little stubby feet
        gfx_draw_rect(x + 5, y + 12, 2, 3, RGB15(26, 24, 18));
        gfx_draw_rect(x + 9, y + 12, 2, 3, RGB15(26, 24, 18));
    } else if (mob_type == 3) { // Goblin Thug (Beastman with mask & sack)
        // Hood & mask
        gfx_draw_rect(x + 4, y + 2 - bob, 8, 6, RGB15(18, 12, 6));
        // Goggle eyes (Glowing yellow)
        gfx_draw_pixel(x + 6, y + 4 - bob, COLOR_YELLOW);
        gfx_draw_pixel(x + 9, y + 4 - bob, COLOR_YELLOW);
        // Body / tunic
        gfx_draw_rect(x + 4, y + 8 - bob, 8, 5, RGB15(10, 14, 8));
        // Pack on back
        gfx_draw_rect(x + 1, y + 5 - bob, 4, 6, RGB15(20, 14, 8));
        // Club / dagger
        gfx_draw_vline(x + 13, y + 6 - bob, 7, RGB15(14, 8, 4));
        // Boots
        gfx_draw_rect(x + 4, y + 13, 3, 3, RGB15(8, 6, 4));
        gfx_draw_rect(x + 9, y + 13, 3, 3, RGB15(8, 6, 4));
    } else { // Damselfly / Worm / Crawler
        gfx_draw_rect(x + 3, y + 6 - bob, 10, 6, RGB15(6, 18, 24));
        gfx_draw_pixel(x + 5, y + 7 - bob, COLOR_RED);
        gfx_draw_pixel(x + 10, y + 7 - bob, COLOR_RED);
        // Wings / antennas
        gfx_draw_hline(x + 1, y + 4 - bob, 6, RGB15(20, 26, 30));
        gfx_draw_hline(x + 9, y + 4 - bob, 6, RGB15(20, 26, 30));
    }
}
