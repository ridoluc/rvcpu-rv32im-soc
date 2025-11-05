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



module RVCPU_registers (
    input   wire        clk,
    input   wire        rst_n,

    input   wire [4:0]  r_addr1,  
    input   wire [4:0]  r_addr2,

    input   wire        w_en,
    input   wire [4:0]  w_addr,
    input   wire [31:0] w_data,

    output  wire [31:0] out1,  
    output  wire [31:0] out2  
);

    reg [31:0] registers[0:31] /*verilator public_flat_rw*/;
    integer i;

    always_ff @( posedge clk ) begin 
        if (!rst_n) begin
            for (i = 0; i<32 ; i=i+1 ) begin
                registers[i] <= 32'b0;
            end
        end else begin
            if (w_en && w_addr != 5'd0)
                registers[w_addr] <= w_data;
            registers[0] <= 32'b0; // Ensure register 0 is always 0
        end
    end

    
    assign out1 = registers[r_addr1];
    assign out2 = registers[r_addr2];

endmodule