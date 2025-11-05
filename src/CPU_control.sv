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

module CPU_control (
    input wire          funct7b1,
    input wire          funct7b6,
    input wire  [2:0]   funct3,
    input  wire [6:0]   opcode,

    output wire [4:0]   ALUcontrol,
    output wire [2:0]   Imm_src,
    output wire         ALU_src,
    output wire         branch,
    output wire         mem_read,
    output wire         mem_write,
    output wire [1:0]   mem_to_reg,
    output wire         reg_write,
    output wire         jump,
    output wire         jump_reg,
    output wire         pc_sel
);

    wire [1:0]   ALU_op;

    Instr_dec instruction_decoder (
        .opcode(opcode),
        .alu_op(ALU_op),
        .ALU_src(ALU_src),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .imm_src(Imm_src),
        .jump(jump),
        .jump_reg(jump_reg),
        .pc_sel(pc_sel)
    );


    ALU_dec alu_dec (
        .funct3(funct3),
        .funct7b1(funct7b1),
        .funct7b6(funct7b6),
        .ALUop(ALU_op),
        .ALUcontrol(ALUcontrol)
    );

    

endmodule