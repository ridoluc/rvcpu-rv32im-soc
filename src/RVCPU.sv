/*
*  RVCPU - Simple RISC-V CPU
* 
*  Author:  ridoluc
*  Date:    Jan 2025
*
*  Simple implementation of a RISC-V CPU. The CPU is single-cycle and implements the RV32I ISA variant. 
*  The CPU comprises of the following components:
*  - Program Counter
*  - Instruction Memory
*  - Register File
*  - ALU
*  - Data Memory
*  - Immediate Extender
*  - Branch Unit
*  - Control Unit
*     - Instruction Decoder
*     - ALU Control
*  - Muxes
*     - Data sources (ALU, Memory, Immediate, PC) to Register File
*     - ALU sources (Register, Immediate) to ALU
*/


/*
    ROM size = 2^10 = 1024
    PC size = 32
    Data Memory size = 2^8 = 256 
*/


module RVCPU #(
    parameter PC_SIZE = 32,
    parameter DATA_MEM_SIZE_LOG = 8 // in Words
)
(
    input wire clk,
    input wire rst_n,

    // Wishbone interface
    output wire          o_wb_we,       // Write enable signal
    output wire          o_wb_stb,      // Strobe signal
    output wire          o_wb_cyc,      // Cycle signal
    output wire [3:0]    o_wb_sel,      // Byte select
    output wire [31:0]   o_wb_address,  // Slave address
    output wire [31:0]   o_wb_data,     // Data to slave
    input wire  [31:0]   i_wb_data,     // Data from slave
    input wire           i_wb_ack,      // Acknowledge signal


    input wire [31:0] instruction_in,
    output wire [PC_SIZE-1:0] PC_out


);
    

    // Datapath Signals
    wire [31:0] instruction /*verilog public*/;  // Instruction
    wire [4:0]  r_addr1;            // Read Address 1   
    wire [4:0]  r_addr2;            // Read Address 2
    wire [4:0]  w_addr;             // Write Address
    wire [31:0] w_data;             // Write Data
    wire [31:0] reg_out1;           // Read Data 1
    wire [31:0] reg_out2;           // Read Data 2
    wire [31:0] alu_result;         // ALU Result   
    wire [31:0] mux_to_alu;         // Mux to ALU

    // Memory Signals
    wire [31:0] mem_out;            // Memory Output
    wire        imem_read;          // Instruction Memory Read
    wire        dmem_read;          // Data Memory Read
    wire        dmem_write;         // Data Memory Write    
    wire [31:0] dmem_address;       // Data Memory Address
    wire [31:0] data_to_reg;        // Data to Register, post processed (LB, LH, LW, LBU, LHU)
    wire [31:0] data_to_mem;        // Data to Memory, post processed (SB, SH, SW)
    wire        mem_ready;          // Memory Ready 


    wire [PC_SIZE-1:0] next_pc_br_unit; // Next PC from branch unit
    wire [PC_SIZE-1:0] pc_to_rd; // Next PC from branch unit
    wire [PC_SIZE-1:0] next_pc;     // Next PC after mux for JALR instruction
    wire [31:0] extended_imm;       // Extended Immediate




    // Control Signals
    wire [4:0] ALUcontrol;      // ALU Control
    wire [2:0] Imm_src;         // Immediate Source
    wire ALU_src;               // ALU Source
    wire branch;                // Branch
    wire mem_read;              // Memory Read
    wire mem_write;             // Memory Write
    wire [1:0] mem_to_reg_sig;  // Memory to Register
    wire reg_write;             // Register Write
    wire jump;                  // Jump
    wire jump_reg;              // Jump and store in register
    wire alu_zero;              // ALU Zero
    wire alu_negative;          // ALU Negative
    wire pc_sel;
    wire [2:0] funct3;          // Funct3 field for ALU operations
    wire stall; // Stall signal to control the flow of the CPU
    wire alu_done;             // ALU Done signal

    wire do_branch;
    wire [PC_SIZE-1:0] pc_plus_4;
    wire [PC_SIZE-1:0] pc_plus_imm;
    reg  flush_fetch;
    reg  flush_reg;             // register to align the flush signal with the clock edge

    // Program Counter  
    reg [PC_SIZE-1:0] PC /*verilog public*/;
    reg [PC_SIZE-1:0] PC_NEXT; // Next PC value

    
    assign r_addr1 = instruction[19:15];  
    assign r_addr2 = instruction[24:20];
    assign w_addr = instruction[11:7];
    assign funct3 = instruction[14:12]; // Funct3 field for ALU operations


    /////////////////////////////////////////////
    //////       Control Unit
    /////////////////////////////////////////////

    CPU_control control_unit (
        .funct7b1(instruction[25]),        // Funct7 bit 1 for multiplication and division
        .funct7b6(instruction[30]),        // Funct7 bit 6 for SUB and SRA
        .funct3(funct3),
        .opcode(instruction[6:0]),
        .ALUcontrol(ALUcontrol),
        .Imm_src(Imm_src),
        .ALU_src(ALU_src),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg_sig),
        .reg_write(reg_write),
        .jump(jump),
        .jump_reg(jump_reg),
        .pc_sel(pc_sel)
    );



    /////////////////////////////////////////////
    //////       Datapath Components
    /////////////////////////////////////////////


    // Instruction Fetch
    // In a branch or jump, the instruction fetch stage is flushed to discard the previosly fetched 
    assign instruction = flush_reg ? 32'b0  : instruction_in;


    // Stall signal for memory operations
    assign stall = (mem_read && !mem_ready) || !alu_done; // If memory is not ready, stall the CPU



    always_ff @(posedge clk) begin
        if (!rst_n) begin
            PC          <= {PC_SIZE{1'b0}};
            PC_NEXT     <= {PC_SIZE{1'b0}}; // Reset PC to zero
            flush_reg   <= 1'b0; // Reset flush register
        end else begin
            if (!stall) begin
                PC <= PC_NEXT;
                PC_NEXT <= ((branch && do_branch) || jump) ? pc_plus_imm : // Branch and JAL
                            (jump_reg)  ?  {alu_result[PC_SIZE-1:0]} :   //JALR
                            PC_NEXT+4;
                flush_reg <= flush_fetch; // Update flush register
            end
        end
    end

    assign PC_out = stall ? PC :PC_NEXT; // Output the current PC value


    // Register File
    RVCPU_registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .r_addr1(r_addr1),
        .r_addr2(r_addr2),
        .w_en(reg_write && !stall), // Write Enable, only if not stalled
        .w_addr(w_addr),
        .w_data(w_data),
        .out1(reg_out1),
        .out2(reg_out2)
    );

    // Multiplexer to select the input to the ALU
    // If ALU_src is 0, use reg_out2 (second register operand),
    // if ALU_src is 1, use the extended immediate value
    assign mux_to_alu = (ALU_src == 1'b0) ? reg_out2 : extended_imm; 

    mux4to1 regmux (
        .sel(mem_to_reg_sig),
        .in0(alu_result),                                       // Op, OpImm
        .in1(data_to_reg),                                      // Load
        .in2(pc_to_rd),                                         // JAL (pc+4), JALR (pc+imm)
        .in3(extended_imm),                                     // LUI
        .out(w_data)
    );

    Imm_extend imm_extend (
        .imm_src(Imm_src),
        .instr(instruction[31:7]),
        .imm(extended_imm)
    );


    // ALU
    ALU #(
        .FAST_MUL_EN(1),  // Enable fast multiplier
        .DIVIDER_EN(1)    // Enable divider
    ) alu (
        .clk(clk),
        .rst_n(rst_n),

        .A(reg_out1),
        .B(mux_to_alu),
        .opcode(ALUcontrol),
        .out(alu_result),
        .zero(alu_zero),
        .negative(alu_negative),

        .done(alu_done) 
    );


    /////////////////////////////////////////////
    //////       Memory Components
    /////////////////////////////////////////////

    // Load and Store Unit
    ls_unit_wishbone ls_unit (
        .clk(clk),
        .rst_n(rst_n),

        .len_select(instruction[13:12]),  // 0:SB, 1:SH, 2:SW
        .mem_read(mem_read),
        .mem_write(mem_write),
        .data_write(reg_out2),
        .data_read(mem_out),
        .dmem_address(alu_result),
        .mem_ready(mem_ready),

        .o_wb_we(o_wb_we),
        .o_wb_stb(o_wb_stb),
        .o_wb_cyc(o_wb_cyc),
        .o_wb_sel(o_wb_sel),
        .o_wb_address(o_wb_address),
        .o_wb_data(o_wb_data),
        .i_wb_data(i_wb_data),
        .i_wb_ack(i_wb_ack)
    );



    Mem_load_dec mem_load_dec (
        .funct3(funct3),
        .data_in(mem_out),
        .data_out(data_to_reg)
    );


    /////////////////////////////////////////////
    //////       Branch Control Unit
    /////////////////////////////////////////////

    assign flush_fetch = (jump || (branch && do_branch) || jump_reg); // Flush the fetch stage if we are jumping or branching

    assign do_branch =  funct3 == 3'b000 && alu_zero        || 
                        funct3 == 3'b001 && !alu_zero       || 
                        funct3 == 3'b100 && alu_negative    || 
                        funct3 == 3'b101 && !alu_negative   || 
                        funct3 == 3'b110 && !alu_zero       ||  // This uses SLTU. If rs1 < rs2, then out is 1 and zero is 0. So for zero negated the comparison is true.
                        funct3 == 3'b111 && alu_zero;

    assign pc_plus_4 = PC + 4;
    assign pc_plus_imm = PC + (extended_imm[PC_SIZE-1:0]);
    assign pc_to_rd = pc_sel ? pc_plus_imm : pc_plus_4;



endmodule