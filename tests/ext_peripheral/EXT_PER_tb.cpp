/**
 * @file EXT_PER_tb.cpp
 * @brief Verilator testbench for EXT_WRAPPER peripheral.
 * 
 * Tests the external peripheral by observing GPIO outputs.
 * Generates `waveform.vcd` when tracing is enabled.
 * 
 * Author: ridoluc
 * Date: 2025-11
 */


#include "VEXT_WRAPPER.h"
#include "verilated.h"
#include <verilated_vcd_c.h> // Add this line
#include "VEXT_WRAPPER___024root.h"
#include <iostream>
#include <iomanip> 
#include <vector>
#include <cassert>

vluint64_t main_time = 0;

VerilatedVcdC* tfp = nullptr; 

void clk_tick(VEXT_WRAPPER* top) {
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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable tracing
    VEXT_WRAPPER* top = new VEXT_WRAPPER;

    tfp = new VerilatedVcdC; // Create trace object
    top->trace(tfp, 99);     // Trace 99 levels of hierarchy
    tfp->open("waveform.vcd"); // Open VCD file

    /////////  Reset the system  /////////
    std::cout << "Resetting the system..." << std::endl;
    top->rst_n = 0; // Assert reset
    clk_tick(top); // Clock tick to apply reset
    top->rst_n = 1; // Deassert reset
    clk_tick(top); // Clock tick to complete reset

    int counter = 0;
    int gpio_out_prev = top->gpio_out; // Initialize previous GPIO output state
    int start_time = main_time;


    while (++counter < 256){
        clk_tick(top);
    };

    std::cout << "T: " << (int)main_time << " GPIO Out: " << std::bitset<8>(top->gpio_out) << " (" << (int)top->gpio_out << ")" << std::endl;


    tfp->close(); // Close VCD file
    delete tfp;
    delete top;
    return 0;
}
