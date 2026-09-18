/*
 * FFXI Advance - Audio Engine Implementation
 * PSG / DirectSound synthesis for GBA
 * Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
 */
#include "audio.h"

/* GBA PSG Rate = 2048 - (131072 / freq_hz) */
#define NOTE_REST 0
#define NOTE_C4   1548
#define NOTE_D4   1602
#define NOTE_E4   1650
#define NOTE_F4   1673
#define NOTE_G4   1714
#define NOTE_A4   1750
#define NOTE_B4   1783
#define NOTE_C5   1798
#define NOTE_D5   1825
#define NOTE_E5   1849
#define NOTE_F5   1861
#define NOTE_G5   1881
#define NOTE_A5   1899
#define NOTE_B5   1915
#define NOTE_C6   1923

typedef struct {
    u16 note;
    u8  duration_frames;
} MusicNote;

/* Iconic FFXI Opening Theme (Vana'diel March excerpt) */
static const MusicNote bgm_title[] = {
    {NOTE_C4, 20}, {NOTE_G4, 20}, {NOTE_E4, 20}, {NOTE_G4, 20},
    {NOTE_C5, 30}, {NOTE_B4, 15}, {NOTE_A4, 15}, {NOTE_G4, 40},
    {NOTE_F4, 20}, {NOTE_A4, 20}, {NOTE_G4, 20}, {NOTE_E4, 20},
    {NOTE_D4, 30}, {NOTE_E4, 15}, {NOTE_F4, 15}, {NOTE_G4, 45},
    {NOTE_C4, 20}, {NOTE_E4, 20}, {NOTE_G4, 20}, {NOTE_C5, 40},
    {NOTE_REST, 10}
};

/* Peaceful Ronfaure Melody */
static const MusicNote bgm_ronfaure[] = {
    {NOTE_E4, 24}, {NOTE_G4, 24}, {NOTE_A4, 24}, {NOTE_B4, 36},
    {NOTE_A4, 12}, {NOTE_G4, 24}, {NOTE_E4, 36}, {NOTE_D4, 12},
    {NOTE_E4, 24}, {NOTE_G4, 24}, {NOTE_A4, 48}, {NOTE_G4, 24},
    {NOTE_A4, 24}, {NOTE_B4, 24}, {NOTE_C5, 36}, {NOTE_B4, 12},
    {NOTE_A4, 24}, {NOTE_G4, 48}, {NOTE_E4, 48},
    {NOTE_REST, 16}
};

/* Battle Theme */
static const MusicNote bgm_battle[] = {
    {NOTE_E4, 8}, {NOTE_E4, 8}, {NOTE_G4, 8}, {NOTE_A4, 12},
    {NOTE_B4, 12}, {NOTE_A4, 8}, {NOTE_G4, 8}, {NOTE_E4, 16},
    {NOTE_D4, 8}, {NOTE_E4, 8}, {NOTE_G4, 12}, {NOTE_A4, 12},
    {NOTE_C5, 16}, {NOTE_B4, 12}, {NOTE_A4, 8}, {NOTE_E4, 20},
    {NOTE_REST, 8}
};

/* Victory Fanfare */
static const MusicNote bgm_victory[] = {
    {NOTE_C5, 10}, {NOTE_C5, 10}, {NOTE_C5, 10}, {NOTE_C5, 20},
    {NOTE_G4, 20}, {NOTE_A4, 20}, {NOTE_C5, 15}, {NOTE_B4, 10},
    {NOTE_C5, 40}, {NOTE_REST, 30}
};

static MusicTrack current_track = BGM_NONE;
static const MusicNote* current_notes = 0;
static int track_length = 0;
static int note_index = 0;
static int note_timer = 0;

void audio_init(void) {
    // Enable Master Sound Power
    REG_SOUNDCNT_X = 0x0080;

    // Modest volume (left/right master volume 4/7) with PSG channels 1 & 2 enabled
    REG_SOUNDCNT_L = 0x3344;
    REG_SOUNDCNT_H = 0x0002; // 50% PSG volume mixing
}

void audio_play_sfx(SoundEffect sfx) {
    switch (sfx) {
        case SFX_CURSOR:
            // High frequency short blip on Channel 1
            REG_SOUND1CNT_L = 0x0000;
            REG_SOUND1CNT_H = 0x8240; // Duty 50%, short envelope
            REG_SOUND1CNT_X = 0x8000 | NOTE_G5;
            break;

        case SFX_CONFIRM:
            // Cheerful two-tone chime
            REG_SOUND1CNT_L = 0x0000;
            REG_SOUND1CNT_H = 0x9380;
            REG_SOUND1CNT_X = 0x8000 | NOTE_C6;
            break;

        case SFX_CANCEL:
            // Lower buzz
            REG_SOUND1CNT_L = 0x0000;
            REG_SOUND1CNT_H = 0x7240;
            REG_SOUND1CNT_X = 0x8000 | NOTE_C4;
            break;

        case SFX_ATTACK:
            // Noise burst on Channel 4 (slash)
            REG_SOUND4CNT_L = 0x9200;
            REG_SOUND4CNT_H = 0x8052;
            break;

        case SFX_CRITICAL:
            // Heavy hit on Channel 4
            REG_SOUND4CNT_L = 0xB300;
            REG_SOUND4CNT_H = 0x8073;
            break;

        case SFX_MAGIC_CAST:
            // Rising sweep on Channel 1
            REG_SOUND1CNT_L = 0x0033; // Frequency sweep upwards
            REG_SOUND1CNT_H = 0x8280;
            REG_SOUND1CNT_X = 0x8000 | NOTE_D4;
            break;

        case SFX_CURE:
            // Soothing ascending arpeggio on Channel 2
            REG_SOUND2CNT_L = 0x9380;
            REG_SOUND2CNT_H = 0x8000 | NOTE_E5;
            break;

        case SFX_LEVEL_UP:
            // Fanfare trigger on Channel 1
            REG_SOUND1CNT_L = 0x0000;
            REG_SOUND1CNT_H = 0xB480;
            REG_SOUND1CNT_X = 0x8000 | NOTE_C6;
            break;

        case SFX_ZONE:
            // Wind chime
            REG_SOUND2CNT_L = 0x8200;
            REG_SOUND2CNT_H = 0x8000 | NOTE_G5;
            break;

        default:
            break;
    }
}

void audio_play_bgm(MusicTrack track) {
    current_track = track;
    note_index = 0;
    note_timer = 0;

    switch (track) {
        case BGM_TITLE_THEME:
            current_notes = bgm_title;
            track_length = sizeof(bgm_title) / sizeof(MusicNote);
            break;
        case BGM_RONFAURE:
            current_notes = bgm_ronfaure;
            track_length = sizeof(bgm_ronfaure) / sizeof(MusicNote);
            break;
        case BGM_BATTLE:
            current_notes = bgm_battle;
            track_length = sizeof(bgm_battle) / sizeof(MusicNote);
            break;
        case BGM_VICTORY:
            current_notes = bgm_victory;
            track_length = sizeof(bgm_victory) / sizeof(MusicNote);
            break;
        default:
            current_notes = 0;
            track_length = 0;
            break;
    }
}

void audio_stop_bgm(void) {
    current_track = BGM_NONE;
    current_notes = 0;
    REG_SOUND2CNT_L = 0;
    REG_SOUND2CNT_H = 0;
}

void audio_update(void) {
    if (!current_notes || track_length <= 0) return;

    if (note_timer > 0) {
        note_timer--;
        return;
    }

    const MusicNote* n = &current_notes[note_index];
    note_timer = n->duration_frames;

    if (n->note == NOTE_REST) {
        REG_SOUND2CNT_L = 0;
    } else {
        // Play note on Channel 2 (Square wave)
        REG_SOUND2CNT_L = 0x6280; // Modest volume envelope
        REG_SOUND2CNT_H = 0x8000 | n->note; // Trigger note
    }

    note_index++;
    if (note_index >= track_length) {
        if (current_track == BGM_VICTORY) {
            // Play victory once then stop
            audio_stop_bgm();
        } else {
            // Loop other tracks
            note_index = 0;
        }
    }
}
