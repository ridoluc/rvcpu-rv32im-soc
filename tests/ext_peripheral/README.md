# External Peripheral Test — Wishbone Expansion

This test demonstrates how to attach an external peripheral to the SoC via the Wishbone bus.

Summary
- A small wrapper instantiates SYSTEM_TOP plus an external peripheral connected to the Wishbone bus.
- The peripheral implements simple registers (a, b, result, control) and a small adder. The CPU writes `a` and `b`, starts the operation, waits for a done bit, reads `result` and drives it to GPIO pins.
- The example C program is at `main.c`.

Addressing and macros
- Peripherals must be mapped in the peripheral region starting at base 0x10000000 (32'h10000000).
- The peripheral region size reserved in the design is 0x00100000 (32'h00100000) therefore up to address 0x100FFFFF.
- Define the macro `EXPOSE_WB_BUS` to expose the Wishbone interface (e.g., add `-DEXPOSE_WB_BUS` to Verilator / compilation flags or enable it in the top-level wrapper).

Usage
1. Build a program and generate `instr_mem.bin` with the provided toolchain:
   - Put your `main.c` in `/home/ridoluc/RVCPU_public/gcc-toolchain/`
   - Run `make all` in that folder (see `gcc-toolchain/README.md`).
2. Copy `instr_mem.bin` into this test folder (or the testbench working directory).
3. Run the testbench:
```
make run
```