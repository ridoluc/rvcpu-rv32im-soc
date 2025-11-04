# Makefile for building a RISC-V program with optional divide instruction support

C_SOURCE = main.c
ELF_FILE = program.elf
BIN_FILE = program.bin
ASM_FILE = instr_mem.bin
LINKER_FILE = linker.ld
CONVERTER_SCRIPT = binary_converter.py

# Set DIV=1 to include divide instructions, or DIV=0 (default) to exclude them.
DIV ?= 1

ifeq ($(DIV),1)

else
    DIVISION_FLAG = -mno-div
endif


all: $(ASM_FILE) disassemble

$(ASM_FILE): $(BIN_FILE)
	python3 $(CONVERTER_SCRIPT) $(BIN_FILE) $(ASM_FILE)

$(BIN_FILE): $(ELF_FILE)
	riscv64-unknown-elf-objcopy -O binary $(ELF_FILE) $(BIN_FILE)

$(ELF_FILE): $(C_SOURCE)
	riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 $(DIVISION_FLAG) -g -o $(ELF_FILE) start.S $(C_SOURCE) -T$(LINKER_FILE) -nostdlib -nostartfiles -lgcc

# Disassemble the ELF file
disassemble: $(ELF_FILE)
	riscv64-unknown-elf-objdump -S $(ELF_FILE) > disassembly.txt

clean:
	rm -f $(ELF_FILE) $(BIN_FILE) $(ASM_FILE)

.PHONY: all