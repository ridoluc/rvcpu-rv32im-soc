/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  CPU control module decodes the instruction opcode and funct3 and funct7 byte 5 to determine the control signals for the datapath.
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