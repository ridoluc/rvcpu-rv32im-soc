# Project TopModule Name
PROJECT = SYSTEM_TOP

# Verilog Source Files (you can add more Verilog files here)
VERILOG_SOURCES = ../../src/CPU_TOP.sv ../../src/RVCPU.sv ../../src/Instr_mem.sv ../../src/RAM.sv ../../src/registers.sv ../../src/ALU.sv ../../src/CPU_control.sv ../../src/ALU_dec.sv ../../src/Instr_dec.sv ../../src/Imm_extend.sv ../../src/Mem_dec.sv ../../src/mux4to1.sv ../../src/Wishbone_master.sv ../../src/GPIO.sv ../../src/JTAG.sv ../../src/Programming_controller.sv ../../src/Muldiv.sv ../../src/UART.sv ../../src/Timer.sv

# C++ Testbench File
TESTBENCH_CPP = ./UART_tb.cpp

# Top module (this should match the name of top module in Verilog)
TOP_MODULE = $(PROJECT)

# Verilator Executable
VERILATOR = verilator

# Compiler Options
CXXFLAGS = -Wall -O2

#Verilator options
VOPTIONS = --public-flat-rw --public --trace

# Directory for Verilator output files
OBJ_DIR = obj_dir

# The final executable name
TARGET = $(OBJ_DIR)/$(PROJECT)

# Detect OS (uname will return 'Darwin' for macOS, 'Linux' for WSL/Linux)
UNAME_S := $(shell uname -s)

# Default rule to build the project
all: $(TARGET)

# Rule to run the simulation
run: all
	./$(TARGET)


# Compilation rule depending on platform
$(TARGET): $(VERILOG_SOURCES) $(TESTBENCH_CPP)
ifeq ($(UNAME_S), Darwin)
    # macOS specific rules
	$(VERILATOR) --cc $(VERILOG_SOURCES) --exe $(TESTBENCH_CPP) $(VOPTIONS) -CFLAGS "$(CXXFLAGS)" --top-module $(TOP_MODULE)
	$(MAKE) -j -C $(OBJ_DIR) -f V$(PROJECT).mk V$(PROJECT)
else ifeq ($(UNAME_S), Linux)
    # WSL/Linux specific rules
	$(VERILATOR) --cc $(VERILOG_SOURCES) --exe $(TESTBENCH_CPP) $(VOPTIONS) -CFLAGS "$(CXXFLAGS)" --top-module $(TOP_MODULE)
	$(MAKE) -j -C $(OBJ_DIR) -f V$(PROJECT).mk V$(PROJECT)
endif
	mv $(OBJ_DIR)/V$(PROJECT) $(TARGET)
	touch $(TARGET)

# Rule to generate the waveform
.PHONY:waves
waves: waveform.vcd 
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd &

# Create the binary file from assembly file
assembly:
	python3 support/RISCVAssembler.py -all support/instr_mem.bin


# Clean rule to remove generated files

clean:
	-rm -rf $(OBJ_DIR)
	-rm -f *.vcd

# Phony targets (not real files)
.PHONY: all clean run waves assembly
