/**
 * EXT_WRAPPER.sv
 *
 * Wrapper module to instantiate the SYSTEM_TOP and connect an external
 * Wishbone peripheral.
 *
 * The external peripheral implements a simple adder. It has registers to
 * hold two 8-bit operands. When both operands are written, it computes their
 * sum and sets a 'done' bit. The result can be read from a result register.
 * Reading the 'done' bit clears it.
 * Address Map:
 * 0x00 - Control Register (read 'done' bit, write ignored)
 * 0x04 - Operand A (write 8-bit value)
 * 0x08 - Operand B (write 8-bit value)
 * 0x0C - Result Register (read 16-bit result)
 *
 *  author ridoluc
 *  date 2025-11
*/


module EXT_WRAPPER (
    input wire clk,
    input wire rst_n,

    output [7:0] gpio_out
);

    wire wb_stb;
    wire wb_cyc;
    wire [31:0] wb_addr;
    wire [31:0] wb_wdata;
    wire wb_we;
    wire [3:0] wb_sel;
    wire [31:0] wb_rdata;
    wire wb_ack_ext;

    SYSTEM_TOP top(
        .clk(clk),
        .rst_n(rst_n),
        .gpio_out(gpio_out),

        .gpio_in(),
        .gpio_dir(),
        .gpio_pullen(),

        .uart_tx(),
        .uart_rx(),

        .tck(),
        .tms(),
        .tdi(),
        .tdo(),

        .wb_stb(wb_stb),
        .wb_cyc(wb_cyc),
        .wb_addr(wb_addr),
        .wb_wdata(wb_wdata),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_rdata(wb_rdata),
        .wb_ack_ext(wb_ack_ext)
    );



    // Instantiate the external module
    WB_per ext_module (
        .clk(clk),
        .rst_n(rst_n),
        .wb_stb(wb_stb),
        .wb_cyc(wb_cyc),
        .wb_addr(wb_addr),
        .wb_wdata(wb_wdata),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_rdata(wb_rdata),
        .wb_ack_ext(wb_ack_ext)
    );

endmodule



module WB_per (
    input wire clk,
    input wire rst_n,

    // Wishbone interface
    input wire wb_stb,
    input wire wb_cyc,
    input wire [31:0] wb_addr,
    input wire [31:0] wb_wdata,
    input wire wb_we,
    input wire [3:0] wb_sel,
    output reg [31:0] wb_rdata,
    output reg wb_ack_ext
);

    // Internal signals
    reg done_bit;
    reg [7:0] OpA, OpB;
    reg [15:0] result;

    localparam CONTROL = 2'b00;
    localparam OPERAND_A = 2'b01;
    localparam OPERAND_B = 2'b10;
    localparam RESULT = 2'b11;


    localparam S_IDLE = 2'b00;
    localparam S_RUN = 2'b01;
    localparam S_DONE = 2'b10;

    reg [1:0] state;

    // Wishbone slave logic
    always @(posedge clk) begin
        if (!rst_n) begin
            done_bit <= 1'b0;
            wb_ack_ext <= 1'b0;

        end else begin
            wb_ack_ext <= 1'b0;
            if (wb_stb && wb_cyc) begin
                if (wb_we) begin
                    // Write operation
                    case (wb_addr[3:2])
                        OPERAND_A: begin
                            OpA <= wb_wdata[7:0];
                        end
                        OPERAND_B: begin
                            OpB <= wb_wdata[7:0];
                        end
                        default: begin
                            // Ignore writes to other addresses
                        end
                    endcase
                end else begin
                    // Read operation
                    wb_ack_ext <= 1'b1;
                    case (wb_addr[3:2])
                        CONTROL: begin
                            wb_rdata <= {31'b0, done_bit};
                            done_bit <= 1'b0; // Clear done bit on read
                        end
                        RESULT: begin
                            wb_rdata <= {16'b0, result};
                        end
                        default: begin
                            wb_rdata <= 32'b0;
                        end
                    endcase
                end
            end
            if(state == S_DONE) begin
                    done_bit <= 1'b1;
            end
        end
    end


    always_ff @( posedge clk ) begin 
        if(!rst_n) begin
            state <= S_IDLE;
            result <= 16'b0;
        end else begin
            case(state)
                S_IDLE: begin
                    if(wb_stb && wb_cyc && wb_we && (wb_addr[3:2] == OPERAND_B)) begin
                        state <= S_RUN;
                    end
                end
                S_RUN: begin
                    state <= S_DONE;
                    result <= {8'b0, OpA} + {8'b0, OpB};
                end
                S_DONE: begin
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end        
    end

endmodule
