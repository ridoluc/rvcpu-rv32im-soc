/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  Instruction decoder module decodes the opcode of the instruction to determine the control signals for the datapath.
*/


`default_nettype none   

module Instr_dec (
    input  wire [6:0]   opcode,

    output reg  [1:0]   alu_op,
    output reg          ALU_src,
    output reg          branch,
    output reg          mem_read,
    output reg          mem_write,
    output reg  [1:0]   mem_to_reg,
    output reg          reg_write,
    output reg  [2:0]   imm_src,
    output reg          jump,
    output reg          jump_reg,
    output reg          pc_sel
    );
    
    localparam [6:0] OP_R    = 7'b0110011;
    localparam [6:0] OP_IMM  = 7'b0010011;
    localparam [6:0] LOAD    = 7'b0000011;
    localparam [6:0] STORE   = 7'b0100011;
    localparam [6:0] BRANCH  = 7'b1100011;
    localparam [6:0] JAL     = 7'b1101111;
    localparam [6:0] JALR    = 7'b1100111;
    localparam [6:0] LUI     = 7'b0110111;
    localparam [6:0] AUIPC   = 7'b0010111;
    localparam [6:0] SYSTEM  = 7'b1110011;


    always_comb begin
        
        case (opcode)
            OP_R: begin
                alu_op = 2'b10;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b1;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            OP_IMM: begin
                alu_op = 2'b11;
                ALU_src = 1'b1;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b1;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            LOAD: begin
                alu_op = 2'b00;
                ALU_src = 1'b1;
                branch = 1'b0;
                mem_read = 1'b1;
                mem_write = 1'b0;
                mem_to_reg = 2'b01;
                reg_write = 1'b1;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            STORE: begin
                alu_op = 2'b00;
                ALU_src = 1'b1;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b1;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                imm_src = 3'b001;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            BRANCH: begin
                alu_op = 2'b01;
                ALU_src = 1'b0;
                branch = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                imm_src = 3'b010;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            JAL: begin
                alu_op = 2'b00;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b10;
                reg_write = 1'b1;
                imm_src = 3'b100;
                jump = 1'b1;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            JALR: begin
                alu_op = 2'b11;
                ALU_src = 1'b1;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b10;
                reg_write = 1'b1;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b1;
                pc_sel = 1'b0;
            end
            LUI: begin
                alu_op = 2'b00;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b11;
                reg_write = 1'b1;
                imm_src = 3'b011;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
            AUIPC: begin
                alu_op = 2'b00;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b10;
                reg_write = 1'b1;
                imm_src = 3'b011;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b1;
            end
            SYSTEM: begin
                alu_op = 2'b00;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end
        
            default: begin
                alu_op = 2'b00;
                ALU_src = 1'b0;
                branch = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 2'b00;
                reg_write = 1'b0;
                imm_src = 3'b000;
                jump = 1'b0;
                jump_reg = 1'b0;
                pc_sel = 1'b0;
            end


             // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump  
            //  7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw 
            //  7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw 
            //  7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R–type 
            //  7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq 
            //  7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I–type ALU 
            //  7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
            //  default: controls = 11'bx_xx_x_x_xx_x_xx_x; // ???


        endcase
    end


endmodule