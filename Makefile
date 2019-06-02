# CHANGEME: Default Orbis Version
ifeq ($(ONI_PLATFORM),)
ONI_PLATFORM := ONI_PLATFORM_STEAM_LINK
endif

# Project name
PROJ_NAME := Mira

# C++ compiler
CPPC	:=	clang

# Linker
LNK		:= ld # ps4-ld, we are compiling for the kernel so this is not going to use the OpenOrbis userland linker

# C compiler
CC		:=	clang

# Archiver
AS		:=	llvm-ar

# Objcopy
OBJCOPY	:=	objcopy

# cppcheck
CPPCHECK := cppcheck

# Output directory, by default is build
ifeq ($(OUT_DIR),)
OUT_DIR	:=	build
endif

# Source directory
SRC_DIR	:=	src

# If the FREEBSD headers path is not set we will try to use the relative path
ifeq ($(BSD_INC),)
BSD_INC := $(SRC_DIR)/External/freebsd-headers/include
endif

# Include directory paths
I_DIRS	:=	-I. -I$(SRC_DIR) -I$(SRC_DIR)/External/freebsd-headers/include -I"$(BSD_INC)"

# Library directory paths
L_DIRS	:=	-L.	-Llib

# Included libraries
LIBS	:= 

# C Defines
C_DEFS	:= -D_KERNEL=1 -D_DEBUG -D_STANDALONE -D"ONI_PLATFORM=${ONI_PLATFORM}" -D__LP64__ -D_M_X64 -D__amd64__

# C++ Flags, -02 Optimizations break shit badly
CFLAGS	:= $(I_DIRS) $(C_DEFS) -fPIE -m64 -std=c++17 -O0 -fno-builtin -nodefaultlibs -nostdlib -nostdinc -fcheck-new -ffreestanding -fno-strict-aliasing -fno-exceptions -fno-asynchronous-unwind-tables -Wall -Werror -Wno-unknown-pragmas

# Assembly flags
SFLAGS	:= -fPIE -m64 -nodefaultlibs -nostdlib

# Linker flags
# -Wl,--build-id=none -T $(SRC_DIR)/link.x --emit-relocs -gc-sections -nmagic --relocatable
LFLAGS	:= -v -pie $(L_DIRS) -nostdlib -entry="mira_entry"

# Calculate the listing of all file paths
CFILES	:=	$(wildcard $(SRC_DIR)/*.c)
CPPFILES :=	$(wildcard $(SRC_DIR)/*.cpp)
SFILES	:=	$(wildcard $(SRC_DIR)/*.s)
OBJS	:=	$(patsubst $(SRC_DIR)/%.s, $(OUT_DIR)/$(SRC_DIR)/%.o, $(SFILES)) $(patsubst $(SRC_DIR)/%.c, $(OUT_DIR)/$(SRC_DIR)/%.o, $(CFILES)) $(patsubst $(SRC_DIR)/%.cpp, $(OUT_DIR)/$(SRC_DIR)/%.o, $(CPPFILES))

ALL_CPP := $(shell find $(SRC_DIR)/ -type f -name '*.cpp')
ALL_C	:= $(shell find $(SRC_DIR)/ -type f -name '*.c')
ALL_S	:= $(shell find $(SRC_DIR)/ -type f -name '*.s')

ALL_SOURCES :=  $(ALL_S) $(ALL_C) $(ALL_CPP)
TO_BUILD := $(ALL_S:$(SRC_DIR)%=$(OUT_DIR)/$(SRC_DIR)%) $(ALL_C:$(SRC_DIR)%=$(OUT_DIR)/$(SRC_DIR)%) $(ALL_CPP:$(SRC_DIR)%=$(OUT_DIR)/$(SRC_DIR)%)
ALL_OBJ_CPP := $(TO_BUILD:.cpp=.o)
ALL_OBJ_C := $(ALL_OBJ_CPP:.c=.o)
ALL_OBJ := $(ALL_OBJ_C:.s=.o)

# Target elf name
TARGET = "$(PROJ_NAME)_Orbis_${ONI_PLATFORM}.elf"

# Target payload name (data + text only, no elf)
PAYLOAD = "$(PROJ_NAME)_Orbis_${ONI_PLATFORM}.bin"

$(TARGET): $(ALL_OBJ)
	@echo "Building for Firmware $(ONI_PLATFORM)..."
	@echo Compiling $(PROJ_NAME)...
	@$(LNK) $(ALL_OBJ) -o $(TARGET) $(LFLAGS) $(LIBS)
	@echo "Creating Payload..."
	@$(OBJCOPY) -O binary $(TARGET) $(PAYLOAD)

$(OUT_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "Checking $< ..."
	@$(CPPCHECK) -q --enable=all --force $(I_DIRS) $<
	@echo "Compiling $< ..."
	@$(CC) $(CFLAGS) $(I_DIRS) -c $< -o $@

$(OUT_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	@echo "Checking $< ..."
	@$(CPPCHECK) -q --enable=all --force $(I_DIRS) $<
	@echo "Compiling $< ..."
	@$(CPPC) $(CFLAGS) $(I_DIRS) -c $< -o $@

$(OUT_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.s
	@echo "Compiling $< ..."
	@$(CC) -c -o $@ $< $(SFLAGS)

.PHONY: clean

clean:
	@echo "Cleaning project..."
	@rm -f $(TARGET) $(PAYLOAD) $(shell find $(OUT_DIR)/ -type f -name '*.o')

create:
	@echo "Creating directories..."
	@mkdir -p $(shell find '$(SRC_DIR)/' -type d -printf '$(OUT_DIR)/%p\n')
