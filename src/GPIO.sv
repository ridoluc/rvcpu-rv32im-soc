`timescale 1ns/1ps
`default_nettype none


module GPIOs #(
    parameter GPIO_NUM = 8 // Number of GPIO pins
)(
    input wire clk,
    input wire rst_n,

    // Wishbone interface
    input wire wb_stb_i,
    input wire wb_cyc_i,
    input wire wb_we_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    input wire [3:0] wb_sel_i, 
    output reg [31:0] wb_dat_o,
    output reg wb_ack_o,

    input wire  [7:0] gpio_in,      // External GPIO inputs
    output wire [7:0] gpio_out,     // External GPIO outputs
    output wire [7:0] gpio_pullen,  // Pull-up enable for GPIOs
    output wire [7:0] gpio_dir      // Direction control for GPIOs
);

    localparam OUT      = 2'b00;
    localparam DIR      = 2'b01;
    localparam PULLEN   = 2'b10;
    localparam IN       = 2'b11;

    wire [31:0] wb_data_in;

    // ------   GPIO registers ------
    // Each GPIO register is 32 bits wide, where only the lower "GPIO_NUM" bits are used
    // The registers are organized as follows:
    // - gpio_reg[OUT]    : Output register for GPIOs
    // - gpio_reg[DIR]    : Direction register for GPIOs (0 = output, 1 = input)
    // - gpio_reg[PULLEN] : Pull-up enable register for GPIOs (1 = enabled, 0 = disabled)
    // - gpio_reg[IN]     : Input register for GPIOs (read-only)
    reg [31:0] gpio_reg[3:0]; // 4 registers for GPIO

    reg [GPIO_NUM-1:0] tmp_reg[1:0];

    // Write data only on the valid GPIOs 
    assign wb_data_in = {{(32-GPIO_NUM){1'b0}}, wb_dat_i[7:0]};

    assign gpio_out = gpio_reg[OUT][7:0];
    assign gpio_dir = gpio_reg[DIR][7:0];
    assign gpio_pullen = gpio_reg[PULLEN][7:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            gpio_reg[0] <= 32'b0;
            gpio_reg[1] <= 32'b0;
            gpio_reg[2] <= 32'b0;
            gpio_reg[3] <= 32'b0; 
            wb_ack_o <= 1'b0;
        end else begin
            wb_ack_o <= 1'b0;
            
            // Update GPIO input register
            gpio_reg[IN][7:0] <= tmp_reg[1];

            if (wb_stb_i & wb_cyc_i) begin
                if(wb_we_i) begin
                    // Write only to OUT, DIR, and PULLEN registers
                    if(wb_adr_i[3:2] != 2'b11) begin
                        case(wb_sel_i)
                            4'b0001: gpio_reg[wb_adr_i[3:2]][ 7: 0] <= wb_data_in[7:0]; // Write to lower byte
                            4'b0010: gpio_reg[wb_adr_i[3:2]][15: 8] <= wb_data_in[7:0]; // Write to second byte
                            4'b0100: gpio_reg[wb_adr_i[3:2]][23:16] <= wb_data_in[7:0]; // Write to third byte
                            4'b1000: gpio_reg[wb_adr_i[3:2]][31:24] <= wb_data_in[7:0]; // Write to upper byte
                            4'b0011: gpio_reg[wb_adr_i[3:2]][15: 0] <= wb_data_in[15:0]; // Write to lower half word
                            4'b1100: gpio_reg[wb_adr_i[3:2]][31:16] <= wb_data_in[15:0]; // Write to upper half word
                            4'b1111: gpio_reg[wb_adr_i[3:2]] <= wb_data_in; // Write full word if all bytes selected
                            default: gpio_reg[wb_adr_i[3:2]] <= wb_data_in; // Write full word if no specific byte selected
                        endcase
                    end
                end else begin
                    // Read operation
                    wb_dat_o <= gpio_reg[wb_adr_i[3:2]];  // Read from GPIO register 1
                    wb_ack_o <= 1'b1; // Acknowledge the transaction
                end
            end
        end
    end

    // Capture asynchronous GPIO inputs
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            tmp_reg[0] <= {{GPIO_NUM{1'b0}}}; // Reset input capture
            tmp_reg[1] <= {{GPIO_NUM{1'b0}}};
        end else begin
            tmp_reg[0] <= gpio_in; // Capture current GPIO inputs
            tmp_reg[1] <= tmp_reg[0]; // Store previous state

        end
    end

endmodule