/**
 * Testbench for Timer peripheral
 * 
 * This testbench verifies the functionality of the Timer peripheral by printing
 * the internal state of the timer at each clock cycle.    
 * Generates `waveform.vcd` when tracing is enabled.
 * 
 * Author: ridoluc
 * Date: 2025-11
 */


#include "VSYSTEM_TOP.h"
#include "verilated.h"
#include <verilated_vcd_c.h> // Add this line
#include "VSYSTEM_TOP___024root.h"
#include <iostream>
#include <iomanip> 
#include <vector>
#include <cassert>

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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable tracing
    VSYSTEM_TOP* top = new VSYSTEM_TOP;
    

    tfp = new VerilatedVcdC; // Create trace object
    top->trace(tfp, 99);     // Trace 99 levels of hierarchy
    tfp->open("waveform.vcd"); // Open VCD file

    /////////  Reset the system  /////////
    std::cout << "Resetting the system..." << std::endl;
    top->rst_n = 0; // Assert reset
    clk_tick(top); // Clock tick to apply reset
    top->rst_n = 1; // Deassert reset
    clk_tick(top); // Clock tick to complete reset

    std::cout << "System reset complete." << std::endl;

    while (main_time < 1000){

        std::cout << "Time: " << main_time
                  << "\t Counter: " << top->rootp->SYSTEM_TOP__DOT__timer__DOT__counter
                  << "\t Prescaler: " << top->rootp->SYSTEM_TOP__DOT__timer__DOT__prescale_cnt
                  << "\t Flag: " << ((top->rootp->SYSTEM_TOP__DOT__timer__DOT__flag) ? 1 : 0)
                  << "\t Enable: " << ((top->rootp->SYSTEM_TOP__DOT__timer__DOT__enable) ? 1 : 0)
                  << "\t GPIO Out: " << std::bitset<8>(top->rootp->SYSTEM_TOP__DOT__gpio_out)
                  << std::endl;
        clk_tick(top);
    }



    tfp->close(); // Close VCD file
    delete tfp;
    delete top;
    return 0;
}
