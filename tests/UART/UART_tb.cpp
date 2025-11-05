/**
 * @file UART_tb.cpp
 * @brief Compact Verilator UART testbench for `SYSTEM_TOP`.
 *
 * Sends a string via `uart_rx` and captures echoed bytes from `uart_tx`.
 * Helpers: `uart_tx` (drive RX to send a byte) and `uart_rx` (sample DUT TX).
 * Commented code shows an alternative passive listener (receive until NUL).
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

#define UART_BAUD_COUNT 100

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


bool uart_rx(VSYSTEM_TOP* top, char* _data) {
    char data = 0;
    int count = 0;


    int start_time = main_time;
    bool res = false;
    bool prev_uart_tx = top->uart_tx;

    // Wait for the UART TX start signal (falling edge detection)
    while ((prev_uart_tx == top->uart_tx || top->uart_tx == 1) && main_time - start_time < 1000) {
        prev_uart_tx = top->uart_tx;
        clk_tick(top); // Continue clocking until data is received
    }
    if (main_time - start_time >= 5000) {
        std::cerr << "UART RX Error: No start signal detected within timeout." << std::endl;
        return 0; // Error condition
    }

    // Read start bit
    while(count++ < UART_BAUD_COUNT) {
        clk_tick(top);

        if(count == UART_BAUD_COUNT / 2 && top->uart_tx != 0) {
            std::cerr << "UART RX Error: Start bit not detected." << std::endl;
            return 0; // Error condition
        }
    }
    // Read data bits
    for(int i = 0; i < 8; i++) {
        count = 0;
        while(count++ < UART_BAUD_COUNT) {
            clk_tick(top);
            if(count == UART_BAUD_COUNT / 2){
                data |= (top->uart_tx << i);
            }
        }
    }

    *_data = data;

    return 1;
}

void uart_tx(VSYSTEM_TOP* top, char data) {
    int count = 0;
    top->uart_rx = 1; // Ensure UART RX is high before starting transmission
    clk_tick(top);
    clk_tick(top);

    // Send start bit
    top->uart_rx = 0; // Start bit is low
    while (count++ < UART_BAUD_COUNT) {
        clk_tick(top);
    }
    
    // Send data bits
    for (int i = 0; i < 8; i++) {
        top->uart_rx = (data >> i) & 1;
        count = 0;
        while (count++ < UART_BAUD_COUNT) {
            clk_tick(top);
        }
    }

    // Send stop bit
    top->uart_rx = 1; // Stop bit is high
    count = 0;
    while (count++ < UART_BAUD_COUNT) {
        clk_tick(top);

    }
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
    clk_tick(top); // Clock tick to complete reset
    clk_tick(top); // Clock tick to complete reset
    top->uart_rx = 1; // Ensure UART RX is high after reset

    char data=1;

    for(int i = 0; i < 30; i++) {
        clk_tick(top); // Clock tick to allow system to stabilize
    }

    char msg[] = "Hello, UART!";
    char* msg_ptr = msg;

    // TRANSMIT STRING AND RECEIVE ECHO
    while(*msg_ptr) {
        uart_tx(top, *msg_ptr); // Transmit each character
        // std::cout << "Transmitted:\t\t" << *msg_ptr << std::endl;
        uart_rx(top, &data);
        std::cout << "Received data:\t\t" << data << std::endl;
        
        msg_ptr++;
    }


    // RECEIVE CHARACTERS UNTIL NULL TERMINATOR
    // while (data != '\0') {
    //     clk_tick(top);
    //     if (uart_rx(top, &data)) {
    //         std::cout << "Received data:\t\t" << data << std::endl;
    //     } else {
    //         std::cerr << "UART RX Error: Failed to receive data." << std::endl;
    //         break; // Exit loop on error
    //     }
    // }


    std::cout << "Simulation finished." << std::endl;

    tfp->close(); // Close VCD file
    delete tfp;
    delete top;
    return 0;
}



