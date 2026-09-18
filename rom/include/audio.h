/*
 * FFXI Advance - Audio Engine Header
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#ifndef AUDIO_H
#define AUDIO_H

#include "gba.h"

typedef enum {
    SFX_NONE = 0,
    SFX_CURSOR,
    SFX_CONFIRM,
    SFX_CANCEL,
    SFX_ATTACK,
    SFX_CRITICAL,
    SFX_MAGIC_CAST,
    SFX_CURE,
    SFX_LEVEL_UP,
    SFX_ZONE,
    SFX_DEFEAT
} SoundEffect;

typedef enum {
    BGM_NONE = 0,
    BGM_TITLE_THEME,    // Vana'diel March
    BGM_RONFAURE,        // Ronfaure peaceful melody
    BGM_BATTLE,          // Battle Theme
    BGM_VICTORY          // Victory Fanfare
} MusicTrack;

/* Initialize GBA Sound Hardware */
void audio_init(void);

/* Sound Effects */
void audio_play_sfx(SoundEffect sfx);

/* Background Music */
void audio_play_bgm(MusicTrack track);
void audio_stop_bgm(void);

/* Update audio sequencer (call once per frame) */
void audio_update(void);

#endif /* AUDIO_H */
