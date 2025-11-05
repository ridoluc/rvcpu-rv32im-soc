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
 

module Timer (
    input  wire        clk,
    input  wire        rst_n,

    // Wishbone interface
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    output reg         wb_ack_o
);

    // Timer registers
    reg        enable;
    reg        flag;
    reg [31:0] counter;
    reg [31:0] prescaler;
    reg [31:0] prescale_cnt;
    reg [31:0] compare;

    // Address map (word offsets)
    localparam REG_CONTROL   = 2'h0; // bit0: enable, bit1: flag (read-only, cleared on write 1)
    localparam REG_COUNTER   = 2'h1; // current counter value (read-only, writable to rst_n)
    localparam REG_PRESCALER = 2'h2; // prescaler value
    localparam REG_COMPARE   = 2'h3; // compare value

    // Wishbone Read logic
    always @(posedge clk) begin
        if (!rst_n) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'b0;
        end else begin
            
            if(wb_cyc_i & wb_stb_i & !wb_we_i) begin
                wb_ack_o <= 1'b1; // ACK on read requests

                case (wb_adr_i[3:2])
                    REG_CONTROL:   wb_dat_o <= {30'd0, flag, enable};
                    REG_COUNTER:   wb_dat_o <= counter;
                    REG_PRESCALER: wb_dat_o <= prescaler;
                    REG_COMPARE:   wb_dat_o <= compare;
                    default:       wb_dat_o <= 32'd0;
                endcase
            end else begin
                wb_ack_o <= 1'b0; // No ACK on other conditions
            end

        end
    end

    // Timer operation
    always @(posedge clk) begin
        if (!rst_n) begin
            counter     <= 32'd0;
            prescaler   <= 32'd0;
            prescale_cnt<= 32'd0;
            compare     <= 32'hFFFF_FFFF;
            enable      <= 1'b0;
            flag        <= 1'b0;
        end else begin
            if (enable) begin
                // prescaler
                if (prescale_cnt >= prescaler) begin
                    prescale_cnt <= 32'd0;
                    counter <= counter + 1;

                    // check compare
                    if (counter == compare) begin
                        flag    <= 1'b1;
                        counter <= 32'd0; // auto-reload style
                    end
                end else begin
                    prescale_cnt <= prescale_cnt + 1;
                end
            end

            // Wishbone writes
            if (wb_cyc_i & wb_stb_i & wb_we_i) begin
                case (wb_adr_i[3:2]) // word addressing
                    REG_CONTROL: begin
                        enable <= wb_dat_i[0];
                        if (wb_dat_i[1]) flag <= 1'b0; // write 1 to clear flag
                    end
                    REG_COUNTER: counter   <= wb_dat_i;
                    REG_PRESCALER: prescaler <= wb_dat_i;
                    REG_COMPARE: compare   <= wb_dat_i;
                endcase
            end
        end
    end


endmodule
