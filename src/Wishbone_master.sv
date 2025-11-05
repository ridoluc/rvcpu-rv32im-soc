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

`default_nettype none

module ls_unit_wishbone(
    input wire clk,
    input wire rst_n,

    input wire  [1:0]   len_select,        // 00:SB, 01:SH, 10:SW
    input wire          mem_read,
    input wire          mem_write,
    input wire  [31:0]  data_write,              // Data to be written to memory
    input wire  [31:0]  dmem_address,
    output wire [31:0]  data_read,             // Data read from memory
    output wire         mem_ready,


    // Wishbone interface
    output reg          o_wb_we,
    output reg          o_wb_stb,
    output reg          o_wb_cyc,
    output reg [3:0]    o_wb_sel,
    output wire [31:0]  o_wb_address,
    output wire [31:0]  o_wb_data,
    input wire [31:0]   i_wb_data,
    input wire          i_wb_ack
);


reg read_done;

assign o_wb_address = dmem_address;
assign o_wb_data = data_write;
assign mem_ready = o_wb_stb && i_wb_ack && !read_done;   // Data is ready when the ack is received during an active transaction
assign data_read = i_wb_data;


always_ff @(posedge clk) begin
    if(!rst_n) begin
        read_done <=1'b0;
    end else begin
        read_done <= 1'b0;
        if(mem_ready) read_done <= 1'b1;
    end 
end


always_comb begin
    if(!rst_n) begin
        o_wb_we = 1'b0;
        o_wb_stb = 1'b0;
        o_wb_cyc = 1'b0;
    end 
    if(mem_read||mem_write) begin
        o_wb_we = mem_write;
        o_wb_stb = 1'b1;
        o_wb_cyc = 1'b1;
    end else begin
        o_wb_we = 1'b0;
        o_wb_stb = 1'b0;
        o_wb_cyc = 1'b0;
    end
end



always_comb begin
    if(mem_write) begin
        case(len_select)
            2'b00: begin
                o_wb_sel = 4'b0001 << dmem_address[1:0]; // 8-bit write
            end
            2'b01: begin
                o_wb_sel = 4'b0011 << dmem_address[1:0]; // 16-bit write
            end
            default: o_wb_sel = 4'b1111; // 32-bit write
        endcase
    end else begin
        o_wb_sel = 4'b1111; // No write
    end

end

endmodule

