
#include "VSYSTEM_TOP.h"
#include "verilated.h"
#include <verilated_vcd_c.h> // Add this line
#include "VSYSTEM_TOP___024root.h"
#include <iostream>
#include <iomanip> 
#include <vector>
#include <cassert>
#include <fstream>
#include <vector>
#include <cstdint>

#define CLK_DIV 2

// Instruction Register (IR) values
#define IR_NOP   0x0
#define IR_MEM_CTRL 0x1 
#define IR_WRITE 0x2
#define IR_READ  0x3
#define IR_DONE  0x4 
// Parameters as compiler defines
#define ADDR_W 10
#define DATA_W 32
#define DR_W (ADDR_W + DATA_W)

#define MEM_FILE "./instr_mem.bin"

#define ASSERT_AND_DUMP(cond) \
    do { \
        if (!(cond)) { \
            std::cerr << "Assertion failed: " #cond << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
            if (tfp) tfp->close(); \
            std::abort(); \
        } \
    } while (0)

vluint64_t main_time = 0;

VerilatedVcdC* tfp = nullptr; 

void clk_tick(VSYSTEM_TOP* top) {
    top->eval();
    if (tfp && main_time > 0) tfp->dump(main_time*10-2);
    top->clk = 1;
    top->eval();
    if (tfp) tfp->dump(main_time*10);

    top->clk = 0;
    top->eval();
    if (tfp) {
        tfp->dump(main_time*10+5); 
        tfp->flush();
    }
    main_time++;
}


void jtag_tick(VSYSTEM_TOP* top, bool tck, bool tms, bool tdi) {
    for(int i = 0; i < CLK_DIV; ++i) clk_tick(top);

    // CLK is low
    top->eval();
    if (tfp && main_time > 0) tfp->dump(main_time*10-2);

    // CLK rising edge
    top->clk = 1;
    top->eval();
    if (tfp) tfp->dump(main_time*10);

    // JTAG signals
    top->tck = tck;
    top->tms = tms;
    top->tdi = tdi;
    top->eval();
    if (tfp) tfp->dump(main_time*10+3);


    // CLK falling edge
    top->clk = 0;
    top->eval();
    if (tfp) {
        tfp->dump(main_time*10+5); 
        tfp->flush();
    }
    main_time++;


    for(int i = 0; i < CLK_DIV; ++i) clk_tick(top);
}

void tick_N(VSYSTEM_TOP* top, int N) {
    for(int i = 0; i < N; ++i) {
        jtag_tick(top, 0, 0, 0); // TCK=0, TMS=0, TDI=0
        jtag_tick(top, 1, 0, 0); // TCK=0, TMS=0, TDI=0
    }
}

void reset(VSYSTEM_TOP* top) {
    top->rst_n = 0;
    jtag_tick(top, 0, 1, 0);
    jtag_tick(top, 1, 1, 0);
    top->rst_n = 1;
    jtag_tick(top, 0, 0, 0);
    jtag_tick(top, 1, 0, 0);
}

void tap_to_shift_ir(VSYSTEM_TOP* top) {
    // Go to Shift-IR: TMS=1,1,0,0
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
    assert(top->rootp->SYSTEM_TOP__DOT__jtag__DOT__tap_state == 11); // Ensure we are in Shift-IR state
}

void tap_to_shift_dr(VSYSTEM_TOP* top) {
    // Go to Shift-DR: TMS=1,0,0
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
}

void shift_ir(VSYSTEM_TOP* top, uint8_t ir_val) {
    tap_to_shift_ir(top);
    // Shift in 4 bits, LSB first
    for (int i = 0; i < 4; ++i) {
        bool bit = (ir_val >> i) & 1;
        jtag_tick(top, 0, 0, bit); jtag_tick(top, 1, 0, bit);
    }
    // Exit1-IR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Update-IR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Run-Test/Idle
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
}

void shift_dr(VSYSTEM_TOP* top, uint64_t dr_val, int dr_len) {
    tap_to_shift_dr(top);
    // Shift in dr_len bits, LSB first
    for (int i = 0; i < dr_len; ++i) {
        bool bit = (dr_val >> i) & 1;
        jtag_tick(top, 0, 0, bit); jtag_tick(top, 1, 0, bit);
    }
    // Exit1-DR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Update-DR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Run-Test/Idle
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
}

uint64_t shift_dr_read(VSYSTEM_TOP* top, int dr_len) {
    tap_to_shift_dr(top);
    uint64_t dr_out = 0;
    for (int i = 0; i < dr_len; ++i) {
        jtag_tick(top, 0, 0, 0);
        dr_out |= (top->tdo ? 1ULL : 0ULL) << i;
        jtag_tick(top, 1, 0, 0);
    }
    // Exit1-DR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Update-DR
    jtag_tick(top, 0, 1, 0); jtag_tick(top, 1, 1, 0);
    // Run-Test/Idle
    jtag_tick(top, 0, 0, 0); jtag_tick(top, 1, 0, 0);
    return dr_out;
}

void write_memory(VSYSTEM_TOP* top, uint64_t addr, uint64_t data) {
    // Shift to WRITE state
    shift_ir(top, IR_WRITE);
    // Shift in address and data
    shift_dr(top, (addr << DATA_W) | data, DR_W);
}

uint64_t read_memory(VSYSTEM_TOP* top, uint64_t addr) {
    // Shift to READ state
    shift_ir(top, IR_READ);
    // Shift in address
    shift_dr(top, addr, ADDR_W);
    // Read data from memory
    tick_N(top, 2); // Wait for memory read operation to complete
    
    return shift_dr_read(top, DATA_W);
}


int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable tracing
    VSYSTEM_TOP* top = new VSYSTEM_TOP;
    

    tfp = new VerilatedVcdC; // Create trace object
    top->trace(tfp, 99);     // Trace 99 levels of hierarchy
    tfp->open("waveform.vcd"); // Open VCD file

    reset(top);

    std::vector<uint32_t> memory;  // Data written to memory

    // Wait a few cycles to be in a known state
    tick_N(top, 10);
    std::cout << "Initial state: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 0); // S_NORMAL_OPS

    // --- Test 1: Enter JTAG_CTRL state ---
    std::cout << "Loading IR_MEM_CTRL to enter JTAG mode..." << std::endl;
    shift_ir(top, IR_MEM_CTRL);

    // Wait for CDC and state change
    tick_N(top, 3);
    std::cout << "Controller state after IR_MEM_CTRL: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 1); // S_JTAG_CTRL


    // read data from file
    std::ifstream infile(MEM_FILE, std::ios::binary);
    if (!infile) {
        std::cerr << "Error opening file" << std::endl;
        return 1;
    }

    
    // --- Test 1.1: Write file content to memory ---
    std::cout << "Writing file content to memory..." << std::endl;
    uint32_t addr = 0;
    uint32_t data_count = 0;
    std::string line;
    while (std::getline(infile, line)) {
        if (line.empty()) continue;
        uint32_t data = static_cast<uint32_t>(std::stoul(line, nullptr, 2));
        memory.push_back(data);
        std::cout << "Writing to address: " << std::dec << addr << " Data: 0x" << std::hex << std::setw(8) << std::setfill('0') << data << std::dec << std::endl;
        write_memory(top, addr, data);
        addr += 4;
        data_count++;
    }

    // Wait for CDC and state change
    tick_N(top, 3);
    std::cout << "Controller state after WRITE: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 1); // Still S_JTAG_CTRL

    // --- Test 1.2: Read from memory ---
    std::cout << "Reading from memory..." << std::endl;
    for(int i = 0; i < data_count; i++) {
        uint32_t data_read = read_memory(top, i*4); // Read data from memory

        std::cout   << "Address: " << std::left << i*4;

        // #define READ_BINARY_OUTPUT
        #ifdef READ_BINARY_OUTPUT
            std::cout << " Data: 0b";
            for (int i = DATA_W - 1; i >= 0; --i) {
                std::cout << ((data_read >> i) & 1);
            }
        #else
            std::cout << " Data: 0x" << std::hex << std::setfill('0') << std::setw(8) << std::right<< data_read << std::dec;
        #endif
        std::cout << " Expected: 0x" << std::hex << std::setfill('0') << std::setw(8) << std::right << memory[i] << std::dec;
        if(data_read != static_cast<int>(memory[i])) {
            std::cout << " <-- MISMATCH!" << std::endl;
            // ASSERT_AND_DUMP(false); // Trigger assertion failure
        } else {
            std::cout << " <-- OK";
        }

        std::cout << std::endl;
        tick_N(top, 3);
    }

    // --- Test 1.3: Return to NORMAL_OPS ---
    std::cout << "Returning to NORMAL_OPS..." << std::endl;
    // tick_N(top, 4);
    shift_ir(top, IR_NOP); // Load NOP to return to normal operations

    // Wait for CDC and state change
    // tick_N(top, 2);
    std::cout << "Controller state after NOP: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 1); // S_JTAG_CTRL


    // --- Test 2: Enter DONE state ---
    tick_N(top, 4);
    std::cout << "Loading IR_DONE to exit JTAG mode..." << std::endl;
    shift_ir(top, IR_DONE);

    // Wait for CDC and state change
    for (size_t i = 0; i < 4; i++) clk_tick(top);
    std::cout << "Controller state after IR_DONE: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 6); // S_DONE

    // --- Test 3: Return to NORMAL_OPS ---
    // The controller should stay in DONE for a few cycles then return to NORMAL_OPS
    tick_N(top, 4);
    std::cout << "Final state: " << (int)top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state << std::endl;
    ASSERT_AND_DUMP(top->rootp->SYSTEM_TOP__DOT__prog_ctrl__DOT__state == 0); // S_NORMAL_OPS

    std::cout << "Controller state transitions are correct." << std::endl;

    
    // Execute the code
    std::cout << "Running the CPU..." << std::endl;
    for (size_t i = 0; i < 1000; i++) clk_tick(top);

    // Print here any outputs or final states as needed
    std::cout << "GPIO Output: " << std::bitset<8>(top->gpio_out) << " (" << (int)top->gpio_out << ")" << std::endl;


    tfp->close(); // Close VCD file
    delete tfp;
    delete top;
    return 0;
}

