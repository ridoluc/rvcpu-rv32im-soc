`default_nettype none
`timescale 1ns/1ps


// Uncomment this line to use the compiled SRAM memory model. Cannot be simulated using verilator
// `define USE_COMPILED_SRAM 

// Uncomment this line to program the instruction memory with a binary file
`define PROGRAM_MEMORY 

// Uncomment this line to expose the Wishbone bus for external peripherals
// `define EXPOSE_WB_BUS 




module SYSTEM_TOP (
    input wire clk,
    input wire rst_n,

    // JTAG interface
    input wire tck,
    input wire tms,
    input wire tdi,
    output wire tdo,

    // GPIO output
    output wire [7:0] gpio_out,
    output wire [7:0] gpio_pullen, 
    output wire [7:0] gpio_dir,     
    input wire [7:0] gpio_in,        



`ifdef EXPOSE_WB_BUS
    output wire wb_stb,
    output wire wb_cyc,
    output wire [31:0] wb_addr,
    output wire [31:0] wb_wdata,
    output wire wb_we,
    output wire [3:0] wb_sel,
    input wire [31:0] wb_rdata,
    input wire wb_ack_ext,
`endif

    // UART interface
    output wire uart_tx,
    input wire uart_rx

);

    localparam PC_SIZE = 32; // Program Counter size
    localparam MEM_ADDR_WIDTH = 10; // Instruction Memory size in log2
    localparam DATA_MEM_ADDR_WIDTH = 16; // 2^8=(256) Number of words Data Memory size in log2

    // Define base addresses and sizes for peripherals
    localparam logic [31:0] GPIO_BASE_ADDR  = 32'h00000000;
    localparam logic [31:0] GPIO_SIZE       = 32'h00000040; // 64 bytes

    localparam logic [31:0] UART_BASE_ADDR  = 32'h00000040;
    localparam logic [31:0] UART_SIZE       = 32'h00000040; // 64 bytes

    localparam logic [31:0] TIMER_BASE_ADDR = 32'h00000080;
    localparam logic [31:0] TIMER_SIZE      = 32'h00000040; // 64 bytes

    localparam logic [31:0] RAM_BASE_ADDR   = 32'h00000100;
    localparam logic [31:0] RAM_SIZE        = 32'h00100000; // 1 MB

    localparam logic [31:0] IMEM_BASE_ADDR  = 32'h80000000;
    localparam logic [31:0] IMEM_SIZE       = 32'h00100000; // 1 MB

    localparam logic [31:0] EXT_BASE_ADDR   = 32'h10000000;
    localparam logic [31:0] EXT_SIZE        = 32'h00100000; // 1 MB

    wire system_rst_n; // System reset signal
    wire jtag_rst_n; // CPU reset signal for programming
    assign system_rst_n = rst_n && jtag_rst_n; // System reset is active low, can be overridden by JTAG reset

    // Wishbone interface signals
    wire          o_wb_we;      // Write enable signal
    wire          o_wb_stb;     // Strobe signal
    wire          o_wb_cyc;     // Cycle signal
    wire [31:0]   o_wb_address;      // Slave address
    wire [31:0]   i_wb_data;    // Data from slave
    wire [31:0]   o_wb_data;    // Data to slave
    wire          i_wb_ack;     // Acknowledge signal
    wire [3:0]    o_wb_sel;     // Byte select    

    wire [31:0]   i_data_ram;
    wire          i_ack_ram;
    wire          i_ack_gpio;
    wire          i_ack_imem;
    wire          i_ack_uart;
    wire          i_ack_timer;
    wire [31:0]   i_data_gpio;
    wire [31:0]   i_data_uart;
    wire [31:0]   i_data_imem;
    wire [31:0]   i_data_timer;

    wire [PC_SIZE-1:0]   PC; // Instruction Memory Data Output
    wire [31:0]   instruction; // Instruction output from Instruction Memory

    
    wire [MEM_ADDR_WIDTH-1:0] mem_waddr; // Memory address for programming
    wire [31:0] mem_wdata; // Memory write data for programming
    wire mem_we; // Memory write enable for programming
    wire mem_control_enable; // Memory control enable for programming



    ///////////////////////////////////////////////////////////////////////
    // CPU Core Instantiation
    ///////////////////////////////////////////////////////////////////////

    RVCPU #(
        .PC_SIZE(PC_SIZE)
    ) cpu (
        .clk(clk),
        .rst_n(system_rst_n),

        // Wishbone interface
        .o_wb_we(o_wb_we),
        .o_wb_stb(o_wb_stb),
        .o_wb_cyc(o_wb_cyc),
        .o_wb_sel(o_wb_sel),
        .o_wb_address(o_wb_address),
        .o_wb_data(o_wb_data),
        .i_wb_data(i_wb_data),
        .i_wb_ack(i_wb_ack),


        .PC_out(PC),  // Program Counter output
        .instruction_in(instruction) // Instruction input from Instruction Memory
    );


    //////////////////////////////////////////////////////////////////////
    // Wishbone Interface Multiplexer
    //////////////////////////////////////////////////////////////////////

    /*
        Base Address mapping:

        GPIO:   0x00000000
        UART:   0x00000040
        TIMER:  0x00000080
        RAM:    0x00000100

    */


    wire ram_select;
    wire gpio_select;
    wire imem_select;
    wire uart_select;
    wire timer_select;
    assign imem_select = o_wb_address[31];
    // verilator lint_off UNSIGNED
    assign gpio_select = (o_wb_address >= GPIO_BASE_ADDR) && (o_wb_address < (GPIO_BASE_ADDR + GPIO_SIZE));
    // verilator lint_on UNSIGNED
    assign uart_select = (o_wb_address >= UART_BASE_ADDR) && (o_wb_address < (UART_BASE_ADDR + UART_SIZE));
    assign timer_select = (o_wb_address >= TIMER_BASE_ADDR) && (o_wb_address < (TIMER_BASE_ADDR + TIMER_SIZE));
    assign ram_select  = (o_wb_address >= RAM_BASE_ADDR) && (o_wb_address < (RAM_BASE_ADDR + RAM_SIZE));


    `ifdef EXPOSE_WB_BUS

        assign wb_stb = (o_wb_address >= EXT_BASE_ADDR) && (o_wb_address < (EXT_BASE_ADDR + EXT_SIZE)) && o_wb_stb;
        assign wb_cyc = o_wb_cyc;
        assign wb_addr = o_wb_address;
        assign wb_wdata = o_wb_data;
        assign wb_we = o_wb_we;
        assign wb_sel = o_wb_sel;

        assign i_wb_ack =  i_ack_ram || i_ack_gpio || i_ack_imem || i_ack_uart || i_ack_timer || wb_ack_ext;

        assign i_wb_data =  i_ack_ram ? i_data_ram : 
                            i_ack_imem ? i_data_imem :
                            i_ack_gpio ? i_data_gpio : 
                            i_ack_uart ? i_data_uart : 
                            i_ack_timer ? i_data_timer : 
                            wb_ack_ext ? wb_rdata : 32'h00000000;
    `else

        assign i_wb_ack =  i_ack_ram || i_ack_gpio || i_ack_imem || i_ack_uart || i_ack_timer;

        assign i_wb_data =  i_ack_ram ? i_data_ram : 
                            i_ack_imem ? i_data_imem :
                            i_ack_gpio ? i_data_gpio : 
                            i_ack_uart ? i_data_uart : 
                            i_ack_timer ? i_data_timer : 32'h00000000;

    `endif



    //////////////////////////////////////////////////////////////////////
    // Instruction Memory
    //////////////////////////////////////////////////////////////////////


    wire [MEM_ADDR_WIDTH-1:0] imem_addr; // Memory address for programming
    wire [31:0] imem_out;

    assign imem_addr = (mem_control_enable) ? mem_waddr : PC[MEM_ADDR_WIDTH-1:0];      // Use the memory address when programming, otherwise use the PC
    assign instruction = (mem_control_enable) ? 32'b0 : imem_out;  // ovevrride instruction output with 0 when programming

    Instr_mem #(
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
    ) instruction_memory (
        .clk(clk),
        .rst_n(system_rst_n),

        .mem_we(mem_we),  
        .mem_wdata(mem_wdata), 

        .PC(imem_addr),
        .instruction(imem_out),

        // Wishbone interface
        .wb_stb_i(o_wb_stb && imem_select),  // Only assert the strobe signal when the address is not in the range of the memory
        .wb_cyc_i(o_wb_cyc),
        .wb_we_i(o_wb_we),
        .wb_adr_i({1'b0,o_wb_address[30:0]}),
        .wb_dat_i(o_wb_data),
        .wb_dat_o(i_data_imem),  // Connect to the instruction memory data output
        .wb_ack_o(i_ack_imem)   // Connect to the instruction memory acknowledge signal
    );


    //////////////////////////////////////////////////////////////////////
    // Data Memory
    //////////////////////////////////////////////////////////////////////

    RAM #(
        .ADDR_WIDTH(DATA_MEM_ADDR_WIDTH)
    ) ram (
        .clk(clk),
        .rst_n(system_rst_n),

        .we(o_wb_we),
        .stb(o_wb_stb && ram_select),  // Only assert the strobe signal when the address is in the range of the memory
        .cyc(o_wb_cyc),
        .address(o_wb_address),
        .data_in(o_wb_data),
        .data_out(i_data_ram),
        .ack(i_ack_ram),
        .sel(o_wb_sel)
    );

    //////////////////////////////////////////////////////////////////////
    // GPIO Peripheral
    //////////////////////////////////////////////////////////////////////

    GPIOs gpio (
        .clk(clk),
        .rst_n(system_rst_n),

        // Wishbone interface
        .wb_stb_i(o_wb_stb && gpio_select),  // Only assert the strobe signal when the address is not in the range of the memory
        .wb_cyc_i(o_wb_cyc),
        .wb_we_i(o_wb_we),
        .wb_adr_i(o_wb_address),
        .wb_dat_i(o_wb_data),
        .wb_dat_o(i_data_gpio),  // Connect to the GPIO data output
        .wb_ack_o(i_ack_gpio),   // Connect to the GPIO acknowledge signal
        .wb_sel_i(o_wb_sel),     // Byte select
        
        .gpio_out(gpio_out),      // GPIO output
        .gpio_pullen(gpio_pullen), // Pull-up enable for GPIOs
        .gpio_dir(gpio_dir),      // Direction control for GPIOs
        .gpio_in(gpio_in)         // External GPIO inputs
    );


    //////////////////////////////////////////////////////////////////////
    // UART Peripheral
    //////////////////////////////////////////////////////////////////////


    UART uart (
        .clk(clk),
        .rst_n(system_rst_n),

        // Wishbone interface
        .wb_stb_i(o_wb_stb && uart_select),  // Only assert the strobe signal when the address is not in the range of the memory
        .wb_cyc_i(o_wb_cyc),
        .wb_we_i(o_wb_we),
        .wb_adr_i(o_wb_address),
        .wb_dat_i(o_wb_data),
        .wb_dat_o(i_data_uart),  // Connect to the UART data output
        .wb_ack_o(i_ack_uart), // Connect to the UART acknowledge signal
        .wb_sel_i(o_wb_sel),    // Byte select

        // UART signals
        .txd(uart_tx), // UART transmit signal
        .rxd(uart_rx)  // UART receive signal

    );


    //////////////////////////////////////////////////////////////////////
    // Timer Peripheral
    //////////////////////////////////////////////////////////////////////

    Timer timer (
        .clk(clk),
        .rst_n(system_rst_n),

        // Wishbone interface
        .wb_stb_i(o_wb_stb && timer_select),  // Only assert the strobe signal when the address is not in the range of the memory
        .wb_cyc_i(o_wb_cyc),
        .wb_we_i(o_wb_we),
        .wb_sel_i(o_wb_sel),
        .wb_adr_i(o_wb_address),
        .wb_dat_i(o_wb_data),
        .wb_dat_o(i_data_timer),  // Connect to the Timer data output
        .wb_ack_o(i_ack_timer)   // Connect to the Timer acknowledge signal
    );


    //////////////////////////////////////////////////////////////////////
    // JTAG Interface
    //////////////////////////////////////////////////////////////////////

    wire [MEM_ADDR_WIDTH-1:0] jtag_addr;
    wire [31:0] jtag_wdata;
    wire [31:0] jtag_rdata;
    wire        jtag_we;
    wire        jtag_req_pulse;
    wire        jtag_en;
    wire        jtag_ack; 



        // Instantiate the JTAG controller
    JTAG #(
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
        .MEM_DATA_WIDTH(32)
    ) jtag (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .rst_n(rst_n),

        .jtag_addr(jtag_addr),
        .jtag_wdata(jtag_wdata),
        .jtag_rdata(jtag_rdata),
        .jtag_en(jtag_en),
        .jtag_req_pulse(jtag_req_pulse),
        .jtag_we(jtag_we),
        .jtag_ack(jtag_ack)
    );

        
    // Instantiate the Programming controller
    Programming_controller #(
        .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
        .MEM_DATA_WIDTH(32)
    )prog_ctrl(
        .clk(clk),
        .rst_n(rst_n),
        .tck(tck),

        .jtag_rst_n(jtag_rst_n),

        .jtag_en(jtag_en),
        .jtag_req_pulse(jtag_req_pulse),
        .jtag_we(jtag_we),
        .jtag_addr(jtag_addr),
        .jtag_wdata(jtag_wdata),
        .jtag_rdata(jtag_rdata),
        .jtag_ack(jtag_ack),

        .mem_addr(mem_waddr),
        .mem_wdata(mem_wdata),
        .mem_rdata(imem_out),
        .mem_we(mem_we),
        .mem_control_enable(mem_control_enable)

    );

endmodule