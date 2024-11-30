C_SRCS := $(wildcard *.c)
A_SRCS := $(wildcard *.asm)
C_OBJS := $(C_SRCS:%=%.o)
A_OBJS := $(A_SRCS:%=%.o)

C_TARGETS := $(basename $(basename $(C_OBJS)))
ASM_TARGETS := $(basename $(basename $(A_OBJS)))

ARTIFACTS := test.txt

CFLAGS = -std=gnu99 -Wall -Wextra
AFLAGS = -g

SDK_VERSION ?= $(shell xcrun -sdk macosx --show-sdk-version)
SDK_PATH ?= $(shell xcrun -sdk macosx --show-sdk-path)
ARCH ?= $(shell uname -m)
ALFLAGS = -macos_version_min $(SDK_VERSION) -lSystem -syslibroot $(SDK_PATH) -e _start -arch $(ARCH)

all: $(C_TARGETS) $(ASM_TARGETS)

artifacts:
	@echo $(C_TARGETS) $(ASM_TARGETS) $(ARTIFACTS) | tr ' ' '\n'

$(C_TARGETS): %: %.c
	@echo "CC -- $@ ($<)"
	@$(CC) $(CFLAGS) -o $@ $<

$(ASM_TARGETS): %: %.asm
	@echo "AS -- $@ ($<)"
	@$(AS) $(AFLAGS) -o $@.o $<
	@$(LD) $(ALFLAGS) -o $@ $@.o
	@rm $@.o

.PHONY: clean
clean:
	@echo "Cleaning up..."
	rm -Rf $(C_TARGETS) $(ASM_TARGETS) $(ARTIFACTS) *.o
