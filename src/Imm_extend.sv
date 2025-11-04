/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  This module extends the immediate value of the instruction to 32 bits.
*  It rearranges the bits from the instruction based on instruction type
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
            default: imm = 32'b0;  // Maybe equal to I?
        endcase
    end

endmodule