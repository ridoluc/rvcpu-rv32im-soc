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
This module is to be revised.
- The fast mul takes two cycle and is to be optimized to one cycle
- the register file in the cpu are written when alu_done is asserted. Review the stall signal
- the div mul unit instantiation inside the ALU necessitate to be reset if the done signal is not asserted.
*/

module Muldiv #(
    parameter FAST_MUL_EN = 0, // Enable fast multiplier 1, Iterative multiplier 0
    parameter DIVIDER_EN = 1 // Enable divider 1, No divider 0
)
(
    input wire clk,
    input wire rst_n,
    input wire [4:0] opcode,
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] result,
    output reg done
);



typedef enum logic [4:0] {
    MUL   = 5'b000_0_1,
    MULH  = 5'b001_0_1,
    MULSU = 5'b010_0_1,
    MULU  = 5'b011_0_1,
    DIV   = 5'b100_0_1,
    DIVU  = 5'b101_0_1,
    REM   = 5'b110_0_1,
    REMU  = 5'b111_0_1
} opcode_t;


typedef enum logic [1:0] {
    IDLE,
    BUSY_MUL,
    BUSY_DIV,
    DONE
} state_t;


state_t state;
reg [4:0] count;
reg [4:0] curr_opcode;
reg [31:0] a_reg, b_reg; // Registers to hold inputs
reg [31:0] quotient, remainder; // For division and remainder
reg [63:0] mul_result; // For multiplication
reg [63:0] div_accumulator; // For division
reg sign_res;
reg sign_a, sign_b; // For signed multiplication/division
reg is_mult_reg, is_div_reg; // For checking if operation is multiplication or division

wire is_mult, is_div;

assign is_mult = (opcode == MUL || opcode == MULH || opcode == MULSU || opcode == MULU);
assign is_div = (opcode == DIV || opcode == DIVU || opcode == REM || opcode == REMU) ;

wire sign_a_w = (opcode == MUL || opcode == MULH || opcode == MULSU || opcode == DIV || opcode == REM) ? a[31] : 1'b0;
wire sign_b_w = (opcode == MUL || opcode == MULH || opcode == DIV || opcode == REM) ? b[31] : 1'b0;
wire [31:0] a_abs = sign_a_w ? -a : a;
wire [31:0] b_abs = sign_b_w ? -b : b;
wire sign_res_w = sign_a_w ^ sign_b_w;


always_ff @(posedge clk) begin
    if(!rst_n) begin
        state <= IDLE;
        mul_result <= 64'b0;
        count <= 5'd0;
        result <= 32'b0;
        done <= 1'b0;
        a_reg <= 32'b0;
        b_reg <= 32'b0;
        curr_opcode <= 5'b0;
        sign_a <= 1'b0;
        sign_b <= 1'b0;
        sign_res <= 1'b0;
        is_mult_reg <= 1'b0;
        is_div_reg <= 1'b0;
        quotient <= 32'b0;
        remainder <= 32'b0; 
        div_accumulator <= 64'b0; // Reset division accumulator
    end else begin
        case(state) 
            IDLE: begin
                done <= 1'b0; // Reset done signal

                // Handle division by zero as a special case (1 cycle)
                if (is_div && DIVIDER_EN && b == 32'b0) begin
                    done <= 1'b1;
                    state <= IDLE;

                    if (opcode == DIV || opcode == DIVU) begin
                        result <= 32'hFFFFFFFF; // Division by zero returns 0xFFFFFFFF
                    end else if (opcode == REM || opcode == REMU) begin
                        result <= a; // Remainder is the dividend
                    end else begin
                        result <= 32'b0; // Default case for unsupported opcodes
                    end
                // Handle case where divider is disabled
                end else if (is_div && !DIVIDER_EN) begin
                    result <= 32'b0; // Return 0 for unsupported operation
                    done   <= 1'b1;   // Operation is "done" in one cycle
                    state  <= IDLE;  // Stay in IDLE
                end else if(is_mult || (is_div && DIVIDER_EN)) begin
                    
                    // Store inputs
                    curr_opcode <= opcode; 
                    is_mult_reg <= is_mult; // Store multiplication flag
                    is_div_reg <= is_div; // Store division flag    

                    // Initialize multiplication result
                    mul_result <= 64'b0; // Reset multiplication result

                    // Division initialization
                    div_accumulator <= {32'b0, a_abs}; // Reset division accumulator
                    quotient <= 32'b0;

                    // Reset count for multiplication/division
                    count <= 5'd0; // Reset count for multiplication

                    sign_a <= sign_a_w;
                    sign_b <= sign_b_w;
                    sign_res <= sign_res_w;

                    a_reg <= a_abs;
                    b_reg <= b_abs;

                    if (is_mult) begin
                        if (FAST_MUL_EN) begin
                            state <= DONE; // Go directly to DONE for fast multiply
                            mul_result <= a_abs * b_abs; // Use registered absolute values for fast path
                        end else begin
                            state <= BUSY_MUL; // Use iterative multiplier
                        end
                    end else if (is_div) begin
                        state <= BUSY_DIV; // Transition to BUSY_DIV state for division
                    end
                end else begin
                    state <= IDLE; // Stay in IDLE if no valid opcode

                end
            end

            BUSY_MUL: begin

                if (b_reg[count]) mul_result <= mul_result + ({32'b0,a_reg} << count);    
                count <= count + 1;

                if(count == 5'd31) begin
                    state <= DONE; // Transition to DONE state when count reaches 0
                end
            end

            BUSY_DIV: begin
                // Restoring division algorithm
                // Step 1: Shift accumulator left
                logic [63:0] shifted_acc = div_accumulator << 1;
                // Step 2: Tentative subtraction of divisor from the upper half of the accumulator
                logic [32:0] temp_rem = {1'b0, shifted_acc[63:32]} - {1'b0, b_reg};

                // Step 3 & 4: Check sign, restore if needed, and set quotient bit
                if (temp_rem[32]) begin // If subtraction result is negative (borrow occurred)
                    // Restore: Remainder is the upper part of the shifted accumulator
                    // Quotient bit is 0
                    div_accumulator <= {shifted_acc[63:32], shifted_acc[31:1], 1'b0};
                end else begin
                    // No restore needed: New remainder is the result of the subtraction
                    // Quotient bit is 1
                    div_accumulator <= {temp_rem[31:0], shifted_acc[31:1], 1'b1};
                end

                count <= count + 1;
                if(count == 5'd31) begin
                    state <= DONE; // Transition to DONE state when count reaches 31
                end

            end

            DONE: begin
                state <= IDLE; // Reset to IDLE after completion
                done <= 1'b1; // Indicate operation is done

                case(curr_opcode)
                    MUL: begin
                        result <= sign_res ? -mul_result[31:0] : mul_result[31:0]; // Properly handle signed multiplication
                    end
                    MULU: begin
                        result <= mul_result[63:32]; // Unsigned multiplication high part
                    end
                    MULH: begin
                        logic [63:0] signed_res = sign_res ? -mul_result : mul_result;
                        result <= signed_res[63:32];
                    end
                    MULSU: begin
                        logic [63:0] signed_res = sign_a ? -mul_result : mul_result; // sign is determined by operand a
                        result <= signed_res[63:32];
                    end
                    DIV, DIVU, REM, REMU: begin
                        logic [31:0] final_quotient = div_accumulator[31:0];
                        logic [31:0] final_remainder = div_accumulator[63:32];
                        quotient <= final_quotient;
                        remainder <= final_remainder;
                        case(curr_opcode)
                            DIV:  result <= sign_res ? -final_quotient : final_quotient;
                            DIVU: result <= final_quotient;
                            REM:  result <= sign_a ? -final_remainder : final_remainder; // Sign of remainder is sign of dividend
                            REMU: result <= final_remainder;
                            default: result <= 32'b0;
                        endcase
                    end
                    default: begin
                        result <= 32'b0; // Default case for unsupported opcodes
                    end
                endcase

            end

            default: begin
                state <= IDLE; // Fallback to IDLE state
            end
        endcase
    end
end


endmodule