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


`default_nettype none


module RAM #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
    ) (
    input wire       clk,
    input wire       rst_n,

    // Wishbone interface


    input wire      we,
    input wire      stb,
    input wire      cyc,
    input wire      [3:0] sel,
    input wire      [DATA_WIDTH-1:0] address,
    input wire      [DATA_WIDTH-1:0] data_in,
    output reg     [DATA_WIDTH-1:0] data_out,
    output reg      ack
);

`ifdef USE_COMPILED_SRAM

    reg [31:0] shifted_data_in;
    wire [DATA_WIDTH-1:0] BWEB;
    wire [31:0] read_data;

    assign BWEB = ~{{8{sel[3]}},{8{sel[2]}},{8{sel[1]}},{8{sel[0]}}};


    always_comb begin
        case(sel)
            4'b0001,
            4'b0010,
            4'b0100,
            4'b1000: shifted_data_in = {24'b0, data_in[7:0]} << (address[1:0] * 8);
            4'b0011: shifted_data_in = {16'h0000, data_in[15:0]};
            4'b1100: shifted_data_in = {data_in[15:0], 16'h0000};
            4'b1111: shifted_data_in = data_in;
            default: shifted_data_in = data_in;
        endcase
    end


    TS1N65LPLL256X32M4 ram( 
			.CLK(clk),
            .CEB(~(cyc && stb)),    // Chip enable for Wishbone - Active low
            .WEB(~we),               // Write enable for Wishbone - Active low

			.A({2'b00,address[ADDR_WIDTH-1:2]}),
			.D(shifted_data_in),
			.BWEB(BWEB),

			.Q(read_data),

			.TSEL(2'b01)
	);

    always @(posedge clk) begin
        if(!rst_n) begin
            ack <= 1'b0; // Reset acknowledge signal
        end else begin
            ack <= 1'b0; // Reset acknowledge signal at the start of each cycle
            if(stb && cyc) begin
                if(!we) begin
                    // Write operation
                    ack <= 1'b1; // Acknowledge the write operation
                end
            end
        end
    end


`else


    reg [31:0] ram_registers[0:(1<<(ADDR_WIDTH-2))-1] /*verilator public_flat_rw*/;
    integer i;

    reg mem_latency;

    reg [31:0] read_data;   
    reg [3:0] byte_en;
    reg [31:0] shifted_data_in;

    always @(posedge clk) begin
        if(!rst_n) begin

            read_data <= {DATA_WIDTH{1'b0}};
            ack <= 1'b0; // Reset acknowledge signal
        end else begin
            ack <= 1'b0; // Reset acknowledge signal at the start of each cycle
            if(stb && cyc) begin 
                if(we) begin
                    if (byte_en[0]) ram_registers[{address[ADDR_WIDTH-1:2]}][ 7: 0] <= shifted_data_in[ 7: 0];
                    if (byte_en[1]) ram_registers[{address[ADDR_WIDTH-1:2]}][15: 8] <= shifted_data_in[15: 8];
                    if (byte_en[2]) ram_registers[{address[ADDR_WIDTH-1:2]}][23:16] <= shifted_data_in[23:16];
                    if (byte_en[3]) ram_registers[{address[ADDR_WIDTH-1:2]}][31:24] <= shifted_data_in[31:24];
                end else begin
                    // Read operation
                    read_data <= ram_registers[{address[ADDR_WIDTH-1:2]}];
                    
                    // ----------------- Memory latency simulation ----------------------
                    // mem_latency <= mem_latency +1; // Set memory latency to indicate a read operation is in progress
                    // ack <= mem_latency; // Acknowledge the read operation
                    // if(ack) begin
                    //     mem_latency <= 0; // Reset memory latency after acknowledging
                    // end
                    // ------------------------------------------------------------------


                    ack <= 1'b1; // Acknowledge the read operation
                end

            end
        end
    end


    // Byte enable and shifted data input for write operations

    always_comb begin
        // Default assignments
        byte_en = 4'b0000;
        shifted_data_in = data_in;

        case(sel)
            // Byte writes
            4'b0001, 4'b0010, 4'b0100, 4'b1000: begin
                byte_en = 4'b0001 << address[1:0];
                shifted_data_in = {24'b0, data_in[7:0]} << (address[1:0] * 8);
            end
            // Half-word writes
            4'b0011, 4'b1100: begin
                if (address[1] == 1'b0) begin // Aligned to lower half-word
                    byte_en = 4'b0011;
                    shifted_data_in = {16'h0000, data_in[15:0]};
                end else begin // Aligned to upper half-word
                    byte_en = 4'b1100;
                    shifted_data_in = {data_in[15:0], 16'h0000};
                end
            end
            // Word write
            4'b1111: begin
                byte_en = 4'b1111;
                shifted_data_in = data_in;
            end
            default: begin
                byte_en = 4'b0000;
                shifted_data_in = data_in;
            end
        endcase
    end

`endif // USE_COMPILED_SRAM


    // The output data is determined by the address bits 1 and 0
    // This allows for byte-level access to the data in the RAM
    // The data returned is aligned to the address bits 1 and 0
    // For example, if address[1:0] = 2'b00, the full 32-bit word is returned.
    // If address[1:0] = 2'b01, the lower 24 bits are returned with the upper 8 bits set to 0
    // The correct bits are further processed by the load decoder in the CPU to return the 
    // correct data to the CPU for LBU, LHU, LB, LH, LW instructions.
    always_comb begin 
        case(address[1:0])
            2'b00: data_out = read_data; 
            2'b01: data_out = {8'b0, read_data[31: 8]}; // 3 byte
            2'b10: data_out = {16'b0, read_data[31:16]}; // 2 byte
            2'b11: data_out = {24'b0, read_data[31:24]}; // 1 byte
        endcase
    end


endmodule