# Makefile for FFXI Advance GBA ROM
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.

CROSS   ?= arm-none-eabi-
CC      := $(CROSS)gcc
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy

BUILD_DIR := build
DIST_DIR  := dist
SRC_DIR   := src
INC_DIR   := include

TARGET_ELF := $(BUILD_DIR)/ffxi_advance.elf
TARGET_GBA := $(DIST_DIR)/FFXI-Advance.gba

ARCH_FLAGS := -mcpu=arm7tdmi -mthumb-interwork
CFLAGS     := $(ARCH_FLAGS) -mthumb -O2 -Wall -Wextra -ffreestanding -nostdlib -I$(INC_DIR)
ASFLAGS    := $(ARCH_FLAGS) -marm
LIBGCC     := $(shell $(CC) $(ARCH_FLAGS) -print-libgcc-file-name)
LDFLAGS    := -T linker.ld -nostdlib

C_SRCS := $(wildcard $(SRC_DIR)/*.c)
S_SRCS := $(wildcard $(SRC_DIR)/*.s)

OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS)) \
        $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(S_SRCS))

.PHONY: all clean test-header

all: $(TARGET_GBA)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(CC) $(ASFLAGS) -c $< -o $@

$(TARGET_ELF): $(OBJS) linker.ld | $(BUILD_DIR)
	$(LD) $(LDFLAGS) $(OBJS) $(LIBGCC) -o $@

$(TARGET_GBA): $(TARGET_ELF) | $(DIST_DIR)
	$(OBJCOPY) -O binary $< $@
	python3 fix_header.py $@
	@echo "==> GBA ROM Successfully Built: $@"

clean:
	rm -rf $(BUILD_DIR)
