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




module Imm_extend (
    input  wire [2:0]  imm_src,
    input  wire [31:7] instr,

    output reg  [31:0] imm
);
    
    localparam [2:0] I = 3'b000;
    localparam [2:0] S = 3'b001;
    localparam [2:0] B = 3'b010;
    localparam [2:0] U = 3'b011;
    localparam [2:0] J = 3'b100;

    always_comb begin
        case (imm_src)
            I: imm = {{20{instr[31]}}, instr[31:20]};
            S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            B: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            U: imm = {instr[31:12], 12'b0};
            J: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
            default: imm = 32'b0;  
        endcase
    end

endmodule