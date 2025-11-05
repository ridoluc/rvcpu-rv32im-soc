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


module  Mem_load_dec (
    input wire  [2:0]   funct3,
    input wire  [31:0]  data_in,
    output reg  [31:0]  data_out
);
    
    always_comb begin
        case (funct3)
            3'b000: data_out = {{24{data_in[7]}}, data_in[7:0]};    // LB
            3'b001: data_out = {{16{data_in[15]}}, data_in[15:0]};  // LH
            3'b010: data_out = data_in;                             // LW
            3'b100: data_out = {24'b0, data_in[7:0]};               // LBU
            3'b101: data_out = {16'b0, data_in[15:0]};              // LHU            
            default: data_out = data_in;                   
        endcase
    end
    
endmodule