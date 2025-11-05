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

module ALU #(
   parameter SIZE=32,
   parameter FAST_MUL_EN=0, // Enable fast multiplier
   parameter DIVIDER_EN=1  // Enable divider
) (
   input wire clk,
   input wire rst_n,

   input  wire [SIZE-1:0] A,
   input  wire [SIZE-1:0] B,
   input  wire [4:0] opcode,
   output reg [SIZE-1:0] out,
   output reg zero,
   output reg negative,
   output reg done
);
   
   wire signed [SIZE-1:0] signed_A = A;
   wire signed [SIZE-1:0] signed_B = B;
   reg [SIZE-1:0] mul_div_res;

   wire done_muldiv;

   Muldiv #(
      .FAST_MUL_EN(FAST_MUL_EN),  // Enable fast multiplier
      .DIVIDER_EN(DIVIDER_EN)    // Enable divider
   )muldiv(
      .clk(clk),
      .rst_n(rst_n&~done_muldiv), // Reset only when not done
      .a(A),
      .b(B),
      .opcode(opcode),
      .result(mul_div_res),
      .done(done_muldiv)
   );


   typedef enum logic [4:0] {
      ADD   = 5'b000_0_0,
      SUB   = 5'b000_1_0,
      AND   = 5'b111_0_0,
      OR    = 5'b110_0_0,
      XOR   = 5'b100_0_0,
      SLL   = 5'b001_0_0,
      SRL   = 5'b101_0_0,
      SRA   = 5'b101_1_0,
      SLT   = 5'b010_0_0,
      SLTU  = 5'b011_0_0,

      // Multiply and Divide operations
      MUL   = 5'b000_0_1,
      MULH  = 5'b001_0_1,
      MULSU = 5'b010_0_1,
      MULU  = 5'b011_0_1,
      DIV   = 5'b100_0_1,
      DIVU  = 5'b101_0_1,
      REM   = 5'b110_0_1,
      REMU  = 5'b111_0_1
   } opcode_t;

   always_comb begin

      done = (opcode == MUL || opcode == MULH || opcode == MULSU || opcode == MULU || 
               opcode == DIV || opcode == DIVU || opcode == REM || opcode == REMU) ? done_muldiv : 1'b1;

      case (opcode)         
         ADD:  out = A + B;
         SUB:  out = A - B; 
         AND:  out = A & B;
         OR:   out = A | B;
         XOR:  out = A ^ B;
         SLL:  out = A << B[4:0];
         SRL:  out = A >> B[4:0];
         SRA:  out = signed_A >>> B[4:0];
         SLT:  out = (signed_A < signed_B) ? 32'b1 : 32'b0;
         SLTU: out = (A < B) ? 32'b1 : 32'b0;

         MUL, MULH, MULSU, MULU, DIV, DIVU, REM ,REMU:
         begin
            out = mul_div_res; // Take the lower 32 bits of the result
         end

         default: out = 32'b0;
      endcase

   end

   assign zero = (out==0); 
   assign negative = out[SIZE-1];
   
endmodule