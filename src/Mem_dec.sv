/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  Memory store and load modules decode the funct3 field of the instruction to determine the memory operation.
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