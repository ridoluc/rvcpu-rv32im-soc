/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  Instruction memory module reads the instruction memory file and outputs the instruction at the PC.
*/


`default_nettype none

module Instr_mem #(
    parameter MEM_ADDR_WIDTH = 10
)(
    input wire clk,
    input wire rst_n,


    input wire mem_we,
    input wire [31:0] mem_wdata,
    input wire [MEM_ADDR_WIDTH-1:0] PC,
    output wire [31:0] instruction,


    // Wishbone interface
    input wire wb_stb_i,
    input wire wb_cyc_i,
    input wire wb_we_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg wb_ack_o
);

reg [31:0] data_out;

`ifdef USE_COMPILED_SRAM


    TSDN65LPLLA1024X32M4M instruction_memory(
        .AA({2'b00, PC[MEM_ADDR_WIDTH-1:2]}), // Registered Address input
        .DA(mem_wdata),               // Data input
        .BWEBA({32{~mem_we}}),         // Byte write enable
        .WEBA(~mem_we),               // Write enable Write=0/Read=1
        .CEBA(1'b0),                  // Chip enable Active low
        .CLKA(clk),                   // Clock input

        .AB({2'b00, wb_adr_i[MEM_ADDR_WIDTH-1:2]}), // Address input for Wishbone
        .DB(wb_dat_i),                     // Data input for Wishbone
        .BWEBB({32{1'b1}}),                   // Byte write enable for Wishbone Active low
        .WEBB(1'b1),                       // Write enable for Wishbone - Read only (Write=0/Read=1)
        .CEBB(~(wb_cyc_i && wb_stb_i)),    // Chip enable for Wishbone - Active low
        .CLKB(clk),                        // Clock input for Wishbone

        .QA(instruction),                  // Output data for instruction memory
        .QB(wb_dat_o)                      // Output data for Wishbone interface
    );


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wb_ack_o <= 1'b0;
            // wb_dat_o <= 32'b0;
        end else begin
            wb_ack_o <= 1'b0;
            // Handle Wishbone interface
            if (wb_stb_i && wb_cyc_i && !wb_we_i) begin
                wb_ack_o <= 1'b1; 
            end
        end
    end


`else  // For FPGA implementation

    reg [31:0] instruction_reg; 
    assign instruction = instruction_reg;
    reg [31:0] instruction_memory[0:(1<<MEM_ADDR_WIDTH)-1];

`ifdef PROGRAM_MEMORY
    initial begin
        $readmemb("./instr_mem.bin", instruction_memory);
    end
`endif // PROGRAM_MEMORY

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            instruction_reg <= 32'b0;
            wb_ack_o <= 1'b0;
            data_out <= 32'b0;
        end else begin
            if(mem_we) begin
                instruction_memory[{2'b00, PC[MEM_ADDR_WIDTH-1:2]}] <= mem_wdata;
            end else begin
                wb_ack_o <= 1'b0;
                instruction_reg <= instruction_memory[{2'b00, PC[MEM_ADDR_WIDTH-1:2]}];

                if (wb_stb_i && wb_cyc_i && !wb_we_i) begin
                    wb_ack_o <= 1'b1; 
                    data_out <= instruction_memory[{2'b00, wb_adr_i[MEM_ADDR_WIDTH-1:2]}];
                end
            end
        end
    end

`endif

always_comb begin 
    case(wb_adr_i[1:0])
        2'b00: wb_dat_o = data_out; 
        2'b01: wb_dat_o = {8'b0, data_out[31: 8]}; // 3 byte
        2'b10: wb_dat_o = {16'b0, data_out[31:16]}; // 2 byte
        2'b11: wb_dat_o = {24'b0, data_out[31:24]}; // 1 byte
    endcase
end

endmodule