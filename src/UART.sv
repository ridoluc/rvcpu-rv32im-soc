/*
 * Project:    RVCPU: SystemVerilog SoC implementing a RV32IM CPU
 *
 * Author:     ridoluc
 * Date:       2025-11
 *
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2025 Luca Ridolfi
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


/*
    UART Module

    This module implements a UART interface with a Wishbone
    bus for configuration and data transfer. It supports
    both transmit and receive operations.

    Address mapping:
    - 0x00: TXDATA (Transmit data register)
    - 0x04: RXDATA (Receive data register)
    - 0x08: CTRL   (Control register)
    - 0x0C: BAUD   (Baud register)

    Control Register Bits:
    - Bit 0: TX_BUSY (Transmitter busy flag - readonly)
    - Bit 1: FULL_BUFF (Transmitter full buffer flag - readonly)
    - Bit 2: RX_READY (Receiver ready flag - readonly)

    Baud rate is set in the BAUD register, which is a 16-bit value
    that determines the number of clock cycles per bit.

    When the data is written to the TXDATA register,
    the UART will start transmitting it. The TX_BUSY flag will be set
    until the transmission is complete. The FULL_BUFF flag indicates
    that there is data ready to be transmitted. Wait until the FULL_BUFF
    flag is cleared before writing new data to the TXDATA register.

*/



`default_nettype none
`timescale 1ns/1ps

module UART (
    input wire clk,
    input wire rst_n,

    // Wishbone interface
    input wire wb_stb_i,
    input wire wb_cyc_i,
    input wire wb_we_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    input wire [3:0] wb_sel_i, 
    output reg [31:0] wb_dat_o,
    output reg wb_ack_o,

    // UART interface
    output reg txd,
    input wire rxd
);


    localparam TXDATA = 2'b00; // Transmit data register
    localparam RXDATA = 2'b01; // Receive data register - READ ONLY
    localparam CTRL   = 2'b10; // Control register  - READ ONLY
    localparam BAUD   = 2'b11; // Baud rate register

    localparam TX_BUSY      = 0; // Transmitter busy flag
    localparam FULL_BUFF    = 1; // Transmitter full buffer flag
    localparam RX_BUSY      = 2; // Receiver busy flag
    localparam RX_READY     = 3; // Receiver ready flag

    reg [31:0] uart_reg[3:0]; // 4 registers for UART


    localparam S_TX_IDLE  = 2'b00;
    localparam S_TX_START = 2'b01;
    localparam S_TX_DATA  = 2'b10;
    localparam S_TX_STOP  = 2'b11;

    reg [1:0]   tx_state;       // State for transmitter
    reg [7:0]   tx_buffer;      // Buffer for transmit data
    reg [3:0]   tx_bit_count;   // Bit counter for transmission
    reg [15:0]  baud_counter_tx;   // Counter for baud rate timing


    localparam S_RX_IDLE  = 2'b00;
    localparam S_RX_START = 2'b01;
    localparam S_RX_DATA  = 2'b10;
    localparam S_RX_STOP  = 2'b11;

    reg [1:0]   rx_state;       // State for receiver
    reg [7:0]   rx_buffer;      // Buffer for received data
    reg [2:0]   rx_bit_count;   // Bit counter for reception
    reg         rxd_sync;       // Synchronized RXD signal
    reg         rxd_prev;       // Previous value of RXD signal
    reg [15:0]  baud_counter_rx;   // Counter for baud rate timing

    ////////////////////////////////////////////////////
    // Wishbone interface handling
    ////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (!rst_n) begin
            uart_reg[0] <= 32'b0;
            uart_reg[1] <= 32'b0;
            uart_reg[2] <= 32'b0;
            uart_reg[3] <= 32'b0;
            wb_ack_o <= 1'b0;
        end else begin
            wb_ack_o <= 1'b0;
        
            if (wb_stb_i & wb_cyc_i) begin
                if(wb_we_i && (wb_adr_i[3:2] == TXDATA || wb_adr_i[3:2] == BAUD)) begin
                    case(wb_sel_i)
                        4'b0001: uart_reg[wb_adr_i[3:2]][ 7: 0] <= wb_dat_i[7:0]; // Write to lower byte
                        4'b0010: uart_reg[wb_adr_i[3:2]][15: 8] <= wb_dat_i[7:0]; // Write to second byte
                        4'b0100: uart_reg[wb_adr_i[3:2]][23:16] <= wb_dat_i[7:0]; // Write to third byte
                        4'b1000: uart_reg[wb_adr_i[3:2]][31:24] <= wb_dat_i[7:0]; // Write to upper byte
                        4'b0011: uart_reg[wb_adr_i[3:2]][15: 0] <= wb_dat_i[15:0]; // Write to lower half word
                        4'b1100: uart_reg[wb_adr_i[3:2]][31:16] <= wb_dat_i[15:0]; // Write to upper half word
                        4'b1111: uart_reg[wb_adr_i[3:2]] <= wb_dat_i; // Write full word if all bytes selected
                        default: uart_reg[wb_adr_i[3:2]] <= wb_dat_i; // Write full word if no specific byte selected
                    endcase

                    if (wb_adr_i[3:2] == TXDATA) begin
                        uart_reg[CTRL][FULL_BUFF] <= 1'b1; // Set full buffer flag when writing to TXDATA
                    end

                end else begin
                    // Read operation
                    wb_dat_o <= uart_reg[wb_adr_i[3:2]];  // Read from UART register
                    wb_ack_o <= 1'b1; // Acknowledge the transaction

                    if (wb_adr_i[3:2] == RXDATA) begin
                        uart_reg[CTRL][RX_READY] <= 1'b0; // Clear RX_READY flag when data is read
                    end
                end
            end


            case(tx_state)
                S_TX_IDLE:begin
                    if (uart_reg[CTRL][FULL_BUFF]) begin
                        uart_reg[CTRL][TX_BUSY]     <= 1'b1;
                        uart_reg[CTRL][FULL_BUFF]   <= 1'b0; // Clear new data flag
                    end
                end
                S_TX_START: begin
                    uart_reg[CTRL][TX_BUSY]     <= 1'b1;
                end
                S_TX_DATA: begin
                    uart_reg[CTRL][TX_BUSY]     <= 1'b1;
                end
                S_TX_STOP: begin
                    if (baud_counter_tx == 0) begin
                        uart_reg[CTRL][TX_BUSY] <= 1'b0;        // Transmission complete
                    end
                end
            endcase


            case(rx_state)
                S_RX_IDLE: begin
                    if (rxd_prev && !rxd_sync) begin // Start bit detected
                        uart_reg[CTRL][RX_BUSY] <= 1'b1;
                    end
                end
                S_RX_START: begin
                    uart_reg[CTRL][RX_BUSY] <= 1'b1; // Set RX_BUSY flag while receiving data

                end
                S_RX_DATA: begin
                    uart_reg[CTRL][RX_BUSY] <= 1'b1; // Set RX_BUSY flag while receiving data
                end
                S_RX_STOP: begin
                    if (baud_counter_rx == 0) begin
                        uart_reg[CTRL][RX_BUSY] <= 1'b0; // Reception complete
                        uart_reg[CTRL][RX_READY] <= 1'b1; // Set RX_READY flag
                        uart_reg[RXDATA] <= {24'b0, rx_buffer}; // Store received data in RXDATA register
                    end
                end
            endcase


        end
    end


    ////////////////////////////////////////////////////
    // UART Transmitter
    ////////////////////////////////////////////////////



    always @(posedge clk) begin
        if (!rst_n) begin
            tx_state                 <= S_TX_IDLE;
            tx_buffer                <= 8'b0;
            tx_bit_count             <= 4'b0;
            txd                      <= 1'b1; 
            baud_counter_tx             <= 16'b0; 
        end else begin





            case (tx_state)
                S_TX_IDLE: begin
                    if (uart_reg[CTRL][FULL_BUFF]) begin
                        tx_buffer                   <= uart_reg[TXDATA][7:0];
                        tx_bit_count                <= 4'b0;
                        tx_state                    <= S_TX_START;
                        baud_counter_tx             <= uart_reg[BAUD][15:0]; // Load baud rate from register
                        txd                         <= 1'b1;                    // Set idle state for TXD
                    end
                end

                S_TX_START: begin
                    txd <= 1'b0;                                    // Start bit
                    if(baud_counter_tx == 0) begin
                        baud_counter_tx <= uart_reg[BAUD][15:0];    // Reset baud counter
                        tx_bit_count <= 4'b0;                       // Reset bit count
                        tx_state <= S_TX_DATA;                      // Move to data state
                    end else begin
                        baud_counter_tx <= baud_counter_tx - 1;     // Decrement baud counter
                    end
                end

                S_TX_DATA: begin
                    txd <= tx_buffer[0];                            // Send the current bit
                    if (baud_counter_tx == 0) begin
                        baud_counter_tx <= uart_reg[BAUD][15:0];    // Reset baud counter
                        tx_buffer <= {1'b0, tx_buffer[7:1]};        // Shift bits to the right
                        tx_bit_count <= tx_bit_count + 1;           // Increment bit count

                        if (tx_bit_count == 7) begin
                            tx_state <= S_TX_STOP;                  // Move to stop state after sending all bits
                        end
                    end else begin
                        baud_counter_tx <= baud_counter_tx - 1;     // Decrement baud counter
                    end
                end

                S_TX_STOP: begin
                    txd <= 1'b1;                                // Stop bit
                    if (baud_counter_tx == 0) begin
                        baud_counter_tx <= uart_reg[BAUD][15:0];// Reset baud counter
                        tx_state <= S_TX_IDLE;                  // Go back to idle state
                    end else begin
                        baud_counter_tx <= baud_counter_tx - 1; // Decrement baud counter
                    end

                end

                default: begin
                    tx_state <= S_TX_IDLE;                      // Default case to avoid latches
                end
            endcase
        end
    end


    ////////////////////////////////////////////////////
    // UART Receiver
    ////////////////////////////////////////////////////



    // Synchronize the RXD signal to the clock domain
    reg [1:0]   rx_crc;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            rxd_sync <= 1'b0; // Reset synchronized RXD signal
            rx_crc <= 2'b0;
            rxd_prev <= 1'b0;
        end else begin
            rx_crc <= {rx_crc[0], rxd};
            rxd_sync <= rx_crc[1]; // Synchronize RXD signal
            rxd_prev <= rxd_sync; // Store previous value of RXD signal 
        end
    end


    // Receiver state machine
    always @(posedge clk) begin
        if (!rst_n) begin
            rx_state <= S_RX_IDLE;
            rx_buffer <= 8'b0;
            rx_bit_count <= 3'b0;
        end else begin



            case (rx_state)
                S_RX_IDLE: begin
                    if (rxd_prev && !rxd_sync) begin // Start bit detected
                        rx_bit_count <= 3'b0;
                        rx_buffer <= 8'b0;
                        rx_state <= S_RX_START;
                        baud_counter_rx <= uart_reg[BAUD][15:0]; // Reset baud counter
                    end
                end

                S_RX_START: begin
                    if (baud_counter_rx == 0) begin
                        baud_counter_rx <= uart_reg[BAUD][15:0]; // Reset baud counter
                        rx_state <= S_RX_DATA;              // Move to data receive state
                    end else  begin
                        baud_counter_rx <= baud_counter_rx - 1; // Decrement baud counter
                    end
                    
                    if(baud_counter_rx == {1'b0, uart_reg[BAUD][15:1]}) begin  // Sample at half the bit period
                        if (rxd_sync == 1'b1) begin // Check for start bit
                            rx_state <= S_RX_IDLE;
                        end
                    end
                end

                S_RX_DATA: begin
                    if (baud_counter_rx == 0) begin
                        baud_counter_rx <= uart_reg[BAUD][15:0]; // Reset baud counter
                        rx_bit_count <= rx_bit_count + 1; // Increment bit count

                        if (rx_bit_count == 7) begin
                            rx_state <= S_RX_STOP; // Move to stop state after receiving all bits
                        end
                    end else begin
                        baud_counter_rx <= baud_counter_rx - 1; // Decrement baud counter
                    end
                    
                    if(baud_counter_rx == {1'b0, uart_reg[BAUD][15:1]}) begin  // Sample at half the bit period
                        rx_buffer <= {rxd_sync, rx_buffer[7:1]}; // Shift bits into buffer
                    end 
                end

                S_RX_STOP: begin
                    if (baud_counter_rx == 0) begin
                        rx_state <= S_RX_IDLE; // Go back to idle state
                    end else begin
                        baud_counter_rx <= baud_counter_rx - 1; // Decrement baud counter
                    end

                end

                default: begin
                    rx_state <= S_RX_IDLE; // Default case to avoid latches
                end

            endcase
        
        end
    end

endmodule
