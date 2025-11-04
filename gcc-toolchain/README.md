## GCC Toolchain & Build Helpers for the RVCPU

This folder contains a minimal toolchain wrapper and conversion script used to compile C programs for the RVCPU and convert the generated binary into a text format that can be loaded into the CPU instruction memory (via Verilog's `$readmemb`).

The workflow is simple: write `main.c` (your program), then run `make all`. The Makefile will produce an ELF, convert it to a raw binary, and then run the Python converter to produce a text file of 32-bit binary strings (one per line) which can be read by the Verilog testbench.

## Contents
- `main.c`          — example C program source (edit this with your code)
- `start.S`         — assembly startup / entry (linked by the Makefile)
- `linker.ld`       — linker script used to layout the program
- `Makefile`        — build rules (runs the cross-gcc, objcopy and converter)
- `binary_converter.py` — Python script that converts raw binary to 32-bit binary strings
- `program.elf`     — (generated) ELF executable
- `program.bin`     — (generated) raw binary image
- `instr_mem.bin`   — (generated) ASCII file of 32-bit binary strings for `$readmemb`

## Prerequisites
- Python 3 (the converter script is Python 3 compatible). Run `python3 --version` to check.
- RISC‑V GNU toolchain in your PATH: `riscv64-unknown-elf-gcc`, `riscv64-unknown-elf-objcopy`, `riscv64-unknown-elf-objdump`. The Makefile uses these exact tool names.

Notes on toolchain options used by the Makefile:
- The compiler command in the Makefile is:

	`riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 $(DIVISION_FLAG) -g -o program.elf start.S main.c -Tlinker.ld -nostdlib -nostartfiles -lgcc`

- You can disable divide support (which adds `-mno-div`) by running `make DIV=0 all`.

## How to build
From this `gcc-toolchain` folder, just run:

```bash
make all
```

What `make all` does (summary):
1. Compile/link `main.c` and `start.S` into `program.elf` using `riscv64-unknown-elf-gcc`.
2. Convert `program.elf` into a raw binary `program.bin` with `riscv64-unknown-elf-objcopy -O binary`.
3. Run the Python converter to create `instr_mem.bin` (ASCII, one 32-bit binary string per line) from `program.bin`.

You can run the three steps manually if you prefer:

```bash
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -g -o program.elf start.S main.c -Tlinker.ld -nostdlib -nostartfiles -lgcc
riscv64-unknown-elf-objcopy -O binary program.elf program.bin
python3 binary_converter.py program.bin instr_mem.bin
```

## About `binary_converter.py`
- The script reads the raw binary in little-endian 32-bit words and writes an ASCII file where each line is a 32-bit binary string (e.g. `00000000000000000000000000000000`).
- This format is intended for use with Verilog `$readmemb` to initialize the instruction memory.

## Using the generated `instr_mem.bin` in your simulation
After the build you must copy `instr_mem.bin` into the simulation working directory (the directory where the Verilog testbench expects to find the file). Example:

```bash
# copy to the simulation folder (adjust path to your setup)
cp instr_mem.bin /path/to/simulation/working/directory/

# example (if your tests directory is used for simulation):
cp instr_mem.bin ../tests/GPIO/
```


## Troubleshooting
- If `riscv64-unknown-elf-gcc` (or `objcopy`/`objdump`) is not found, add your RISC‑V toolchain `bin/` path to `PATH` or install a RISC‑V toolchain. Example toolchain names: `riscv64-unknown-elf-` (GNU embedded) or vendor toolchains.



