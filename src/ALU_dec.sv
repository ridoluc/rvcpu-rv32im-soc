/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  ALU decoder module decodes the ALU control signals based on the instruction bytes funct3 and funct7 byte 5.
*  Uses funct3 and funct7 byte 5 to determine the ALU operation to be performed together with ALUop signal from the control unit. 
*/


module ALU_dec (
    input wire        funct7b1,
    input wire        funct7b6,
    input wire  [2:0] funct3,
    input wire  [1:0] ALUop,
    output reg [4:0] ALUcontrol
);

    wire [4:0] funct3_7b6b1 = {funct3, funct7b6, funct7b1}; // Concatenate funct3 and funct7 bits 6 and 5

    always_comb begin
        case (ALUop)
            2'b01: begin    // Branch
                case(funct3)  // Bits 2:1 of funct3 define the alu control value. Bit zero is unnecessary
                    3'b000: ALUcontrol = 5'b00010; // BEQ - SUB
                    3'b001: ALUcontrol = 5'b00010; // BNE - SUB
                    3'b100: ALUcontrol = 5'b00010; // BLT - SUB
                    3'b101: ALUcontrol = 5'b00010; // BGE - SUB
                    3'b110: ALUcontrol = 5'b01100; // BLTU - SLTU
                    3'b111: ALUcontrol = 5'b01100; // BGEU - SLTU
                    default: ALUcontrol = 5'b00010; // Default to SUB
                endcase
            end
            2'b00: begin    // Load/Store
                ALUcontrol = 5'b00000; // ADD
            end
            2'b11: begin    // I-type
                if (funct3 == 3'b101) begin
                    ALUcontrol = funct3_7b6b1; // SRAI
                end else begin
                    ALUcontrol = {funct3,2'b00};  // Maybe in hardware I can keep all equal to {funct3,1'b0,1'b0} and change only the SUB case. Need to check easiest implementation
                end
            end
            default: begin  // R-type (2'b10)
                ALUcontrol = funct3_7b6b1;


                // case (funct3_7b6b1)
                //     4'b000_0: ALUcontrol = 4'b0000; // ADD
                //     4'b000_1: ALUcontrol = 4'b0001; // SUB
                //     4'b001_0: ALUcontrol = 4'b0010; // SLL
                //     4'b010_0: ALUcontrol = 4'b0100; // SLT
                //     4'b011_0: ALUcontrol = 4'b0110; // SLTU
                //     4'b100_0: ALUcontrol = 4'b1000; // XOR
                //     4'b101_0: ALUcontrol = 4'b1010; // SRL
                //     4'b101_1: ALUcontrol = 4'b1011; // SRA
                //     4'b110_0: ALUcontrol = 4'b1100; // OR
                //     4'b111_0: ALUcontrol = 4'b1110; // AND
                // endcase
            end

        endcase
    end

endmodule