/*
 * FFXI Advance - GBA Hardware Definition Header
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#ifndef GBA_H
#define GBA_H

#include <stdint.h>
#include <stdbool.h>

typedef uint8_t   u8;
typedef uint16_t  u16;
typedef uint32_t  u32;
typedef int8_t    s8;
typedef int16_t   s16;
typedef int32_t   s32;

typedef volatile uint8_t   vu8;
typedef volatile uint16_t  vu16;
typedef volatile uint32_t  vu32;
typedef volatile int8_t    vs8;
typedef volatile int16_t   vs16;
typedef volatile int32_t   vs32;

#define SCREEN_WIDTH   240
#define SCREEN_HEIGHT  160

/* Memory Base Addresses */
#define MEM_EWRAM      0x02000000
#define MEM_IWRAM      0x03000000
#define MEM_IO         0x04000000
#define MEM_PALETTE    ((vu16*)0x05000000)
#define MEM_PALETTE_OBJ ((vu16*)0x05000200)
#define MEM_VRAM       ((vu16*)0x06000000)
#define MEM_VRAM_FRONT ((vu16*)0x06000000)
#define MEM_VRAM_BACK  ((vu16*)0x0600A000)
#define MEM_OAM        ((vu16*)0x07000000)
#define MEM_ROM        0x08000000
#define MEM_SRAM       ((vu8*)0x0E000000)

/* Display Control */
#define REG_DISPCNT    (*(vu16*)(MEM_IO + 0x0000))
#define REG_DISPSTAT   (*(vu16*)(MEM_IO + 0x0004))
#define REG_VCOUNT     (*(vu16*)(MEM_IO + 0x0006))

/* Video Modes */
#define MODE_0         0x0000
#define MODE_1         0x0001
#define MODE_2         0x0002
#define MODE_3         0x0003
#define MODE_4         0x0004
#define MODE_5         0x0005

#define BG0_ENABLE     0x0100
#define BG1_ENABLE     0x0200
#define BG2_ENABLE     0x0400
#define BG3_ENABLE     0x0800
#define OBJ_ENABLE     0x1000
#define BACKBUFFER     0x0010

/* Background Control */
#define REG_BG0CNT     (*(vu16*)(MEM_IO + 0x0008))
#define REG_BG1CNT     (*(vu16*)(MEM_IO + 0x000A))
#define REG_BG2CNT     (*(vu16*)(MEM_IO + 0x000C))
#define REG_BG3CNT     (*(vu16*)(MEM_IO + 0x000E))

/* Keypad Input (active low: 0 = pressed, 1 = released) */
#define REG_KEYINPUT   (*(vu16*)(MEM_IO + 0x0130))

#define KEY_A          0x0001
#define KEY_B          0x0002
#define KEY_SELECT     0x0004
#define KEY_START      0x0008
#define KEY_RIGHT      0x0010
#define KEY_LEFT       0x0020
#define KEY_UP         0x0040
#define KEY_DOWN       0x0080
#define KEY_R          0x0100
#define KEY_L          0x0200
#define KEY_MASK       0x03FF

/* Sound Registers */
#define REG_SOUNDCNT_L (*(vu16*)(MEM_IO + 0x0080))
#define REG_SOUNDCNT_H (*(vu16*)(MEM_IO + 0x0082))
#define REG_SOUNDCNT_X (*(vu16*)(MEM_IO + 0x0084))

/* Sound Channel 1 (Tone & Sweep) */
#define REG_SOUND1CNT_L (*(vu16*)(MEM_IO + 0x0060))
#define REG_SOUND1CNT_H (*(vu16*)(MEM_IO + 0x0062))
#define REG_SOUND1CNT_X (*(vu16*)(MEM_IO + 0x0064))

/* Sound Channel 2 (Tone) */
#define REG_SOUND2CNT_L (*(vu16*)(MEM_IO + 0x0068))
#define REG_SOUND2CNT_H (*(vu16*)(MEM_IO + 0x006C))

/* Sound Channel 3 (Wave Output) */
#define REG_SOUND3CNT_L (*(vu16*)(MEM_IO + 0x0070))
#define REG_SOUND3CNT_H (*(vu16*)(MEM_IO + 0x0072))
#define REG_SOUND3CNT_X (*(vu16*)(MEM_IO + 0x0074))

/* Sound Channel 4 (Noise) */
#define REG_SOUND4CNT_L (*(vu16*)(MEM_IO + 0x0078))
#define REG_SOUND4CNT_H (*(vu16*)(MEM_IO + 0x007C))

/* Color helpers: 15-bit BGR (5 bits each: 0-31) */
#define RGB15(r, g, b)  ((u16)(((r) & 0x1F) | (((g) & 0x1F) << 5) | (((b) & 0x1F) << 10)))

/* Standard Vana'diel Palette Colors (15-bit) */
#define COLOR_BLACK       RGB15(0, 0, 0)
#define COLOR_WHITE       RGB15(31, 31, 31)
#define COLOR_GRAY        RGB15(15, 15, 15)
#define COLOR_DARK_GRAY   RGB15(7, 7, 7)
#define COLOR_LIGHT_GRAY  RGB15(22, 22, 22)
#define COLOR_RED         RGB15(31, 6, 6)
#define COLOR_GREEN       RGB15(6, 26, 6)
#define COLOR_BLUE        RGB15(6, 12, 31)
#define COLOR_YELLOW      RGB15(31, 29, 6)
#define COLOR_CYAN        RGB15(6, 28, 28)
#define COLOR_MAGENTA     RGB15(28, 6, 28)
#define COLOR_ORANGE      RGB15(31, 18, 2)
#define COLOR_GOLD        RGB15(28, 24, 8)
#define COLOR_NAVY        RGB15(2, 4, 12)
#define COLOR_FOREST      RGB15(4, 16, 6)
#define COLOR_SAND        RGB15(27, 24, 16)
#define COLOR_BROWN       RGB15(16, 10, 4)
#define COLOR_PURPLE      RGB15(18, 6, 24)

/* Wait for VBlank */
static inline void gba_wait_vblank(void) {
    while (REG_VCOUNT >= 160);
    while (REG_VCOUNT < 160);
}

/* Input state tracking */
typedef struct {
    u16 current;
    u16 previous;
} InputState;

static inline void input_update(InputState* state) {
    state->previous = state->current;
    state->current = (~REG_KEYINPUT) & KEY_MASK;
}

static inline bool input_is_down(const InputState* state, u16 key) {
    return (state->current & key) != 0;
}

static inline bool input_is_pressed(const InputState* state, u16 key) {
    return ((state->current & key) != 0) && ((state->previous & key) == 0);
}

static inline bool input_is_released(const InputState* state, u16 key) {
    return ((state->current & key) == 0) && ((state->previous & key) != 0);
}

#endif /* GBA_H */
