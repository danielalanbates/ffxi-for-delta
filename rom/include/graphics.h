/*
 * FFXI Advance - Graphics Engine Header
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#ifndef GRAPHICS_H
#define GRAPHICS_H

#include "gba.h"

/* Initialize video mode for FFXI Advance (Mode 3, 240x160 15-bit color) */
void gfx_init(void);

/* Clear screen with a solid color */
void gfx_clear(u16 color);

/* Pixel drawing */
void gfx_draw_pixel(int x, int y, u16 color);

/* Shapes */
void gfx_draw_rect(int x, int y, int w, int h, u16 color);
void gfx_draw_rect_outline(int x, int y, int w, int h, u16 color);
void gfx_draw_hline(int x, int y, int length, u16 color);
void gfx_draw_vline(int x, int y, int length, u16 color);

/* Classic FFXI Blue Marble Menu Window with border */
void gfx_draw_window(int x, int y, int w, int h, const char* title);
void gfx_draw_subwindow(int x, int y, int w, int h);

/* Text Rendering */
void gfx_draw_char(int x, int y, char c, u16 color, u16 bg_color, bool transparent_bg);
void gfx_draw_string(int x, int y, const char* str, u16 color, u16 bg_color, bool transparent_bg);
void gfx_draw_string_shadow(int x, int y, const char* str, u16 color);

/* Stat Bars / Gauges */
void gfx_draw_gauge(int x, int y, int w, int h, int current, int max, u16 fill_color, u16 bg_color);

/* Character & Monster Sprites */
void gfx_draw_icon(int x, int y, int icon_id);
void gfx_draw_player_sprite(int x, int y, int race, int job, int dir, int anim_frame);
void gfx_draw_mob_sprite(int x, int y, int mob_type, int dir, int anim_frame);

#endif /* GRAPHICS_H */
