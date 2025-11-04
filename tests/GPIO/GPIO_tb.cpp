/**
 * @file GPIO_tb.cpp
 * @brief Testbench for the GPIO interface in VSYSTEM_TOP (Verilator).
 *
 * Drives gpio_in with an 8-bit counter (0..255), pulses the clock,
 * asserts/deasserts reset at start, and monitors gpio_out for changes.
 * If gpio_out does not change within a configurable timeout (100 cycles),
 * the test reports a timeout and exits. A VCD waveform ("waveform.vcd")
 * is produced for post-simulation inspection.
 *
 * @author ridoluc
 * @date 2025-11
 */

#include "VSYSTEM_TOP.h"
#include "verilated.h"
#include <verilated_vcd_c.h> 
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

    int counter = 0;
    int gpio_out_prev = top->gpio_out; // Initialize previous GPIO output state
    int start_time = main_time;

    while (++counter < 256){
        top->gpio_in = counter; // Set GPIO input
        start_time = main_time; // Reset start time for next iteration
        while(gpio_out_prev == top->gpio_out && start_time + 100 > main_time) {
            clk_tick(top); // Wait for GPIO output to change
        }
        if (start_time + 100 <= main_time) {
            std::cout << "Timeout: GPIO output did not change within 100 cycles." << std::endl;
            break; // Exit if no change in GPIO output after 100 cycles
        }
        gpio_out_prev = top->gpio_out; // Update previous GPIO output state
        std::cout << "T: " << (int)main_time << " Counter: " << (int)counter << ", GPIO Out: " << std::bitset<8>(top->gpio_out) << "(" << (int)top->gpio_out << ")" << std::endl;

    }



    tfp->close(); // Close VCD file
    delete tfp;
    delete top;
    return 0;
}
