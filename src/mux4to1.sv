/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  This module implements a 4-to-1 multiplexer.
*/


`default_nettype none

module mux4to1 (
    input wire [1:0]  sel,
    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [31:0] in3,
    output wire [31:0] out
);

    assign out = (sel == 2'b00) ? in0 : 
                 (sel == 2'b01) ? in1 : 
                 (sel == 2'b10) ? in2 :
                 in3;

endmodule