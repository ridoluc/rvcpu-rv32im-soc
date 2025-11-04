/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  This module implements the 32 CPU registers.
*/



module RVCPU_registers (
    input   wire        clk,
    input   wire        rst_n,

    input   wire [4:0]  r_addr1,  
    input   wire [4:0]  r_addr2,

    input   wire        w_en,
    input   wire [4:0]  w_addr,
    input   wire [31:0] w_data,

    output  wire [31:0] out1,  
    output  wire [31:0] out2  
);

    reg [31:0] registers[0:31] /*verilator public_flat_rw*/;
    integer i;

    always_ff @( posedge clk ) begin 
        if (!rst_n) begin
            for (i = 0; i<32 ; i=i+1 ) begin
                registers[i] <= 32'b0;
            end
        end else begin
            if (w_en && w_addr != 5'd0)
                registers[w_addr] <= w_data;
            registers[0] <= 32'b0; // Ensure register 0 is always 0
        end
    end

    
    assign out1 = registers[r_addr1];
    assign out2 = registers[r_addr2];

endmodule