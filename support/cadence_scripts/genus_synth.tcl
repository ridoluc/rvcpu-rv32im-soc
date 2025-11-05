####################################################################
##
##          GENUS SYNTHESYS FLOW SCRIPT
## 
####################################################################


####################################################################
## Variables Setup
####################################################################

# Design name should match the top-level module name in the HDL file.
#  JTAG.sv Programming_controller.sv GPIO.sv

set HDL_FILES [list CPU_TOP.sv RVCPU.sv ALU.sv ALU_dec.sv CPU_control.sv Imm_extend.sv Instr_dec.sv Mem_dec.sv mux4to1.sv registers.sv Wishbone_master.sv JTAG.sv Programming_controller.sv GPIO.sv Muldiv.sv RAM.sv Instr_mem.sv UART.sv Timer.sv]
set _HDL_DIRECTORY ./SRC
set DESIGN SYSTEM_TOP 

# Clock name should match the clock pin name (i.e. clk, CLK, ...)
set CLOCK_NAME clk
set CLOCK_PERIOD_ps 4000

set GEN_EFF medium
set MAP_OPT_EFF high

set _OUTPUTS_PATH OUTPUTS
set _REPORTS_PATH REPORTS

####################################################################
## Environment Settings and library setup
####################################################################


set_db init_hdl_search_path $_HDL_DIRECTORY;
set_db library "/ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65lpbwp7t_220a/tcbn65lpbwp7twc.lib \
                /ibe/users/lr524/SRAM_LICENCE/ts1n65lpll256x32m4_220a/SYNOPSYS/ts1n65lpll256x32m4_220a_tt1p2v25c.lib \
                /ibe/users/lr524/SRAM_LICENCE/tsdn65lplla1024x32m4m_200a/SYNOPSYS/tsdn65lplla1024x32m4m_200a_tt1p2v25c.lib"
set_db lef_library "/ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/lef/tcbn65lpbwp7t_141a/lef/tcbn65lpbwp7t_9lmT2.lef \
                    /ibe/users/lr524/SRAM_LICENCE/tsdn65lplla1024x32m4m_200a/LEF/tsdn65lplla1024x32m4m_200a_5m.lef \
                    /ibe/users/lr524/SRAM_LICENCE/ts1n65lpll256x32m4_220a/LEF/ts1n65lpll256x32m4_220a_5m.lef \
                    /ibe/users/lr524/RVCPU/scripts/PLL_25M_400M.lef"
set_db cap_table_file "/ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/lef/tcbn65lpbwp7t_141a/techfiles/captable/cln65lp_1p09m+alrdl_top2_rcworst.captable"


# Output verbosity level - 1 (default) to 11
set_db information_level 4;

set_db use_tiehilo_for_const duplicate;

####################################################################
## Load Design
####################################################################

# Read HDL files from the specified directory
# Use option -vhd for VHDL files, -verilog for Verilog files, or -sv for SystemVerilog files.

read_hdl -sv ${HDL_FILES}
elaborate ${DESIGN}

check_design -unresolved
check_design -unloaded


####################################################################
## Constraints Setup
####################################################################
# Set time units for SDC commands to be consistent tith Genus commands
set_time_unit -picoseconds
set_load_unit -femtofarads

# Define the system clock
create_clock -domain domain1 -name ${CLOCK_NAME} -period ${CLOCK_PERIOD_ps} [get_db ports ${CLOCK_NAME}]
set_db clock:${DESIGN}/${CLOCK_NAME} .setup_uncertainty [expr 0.02 * ${CLOCK_PERIOD_ps}]
set_clock_uncertainty -hold  [expr 0.02 * ${CLOCK_PERIOD_ps}] ${CLOCK_NAME} 
set_clock_uncertainty -setup [expr 0.02 * ${CLOCK_PERIOD_ps}] ${CLOCK_NAME} 
set_clock_transition -rise  50 ${CLOCK_NAME}
set_clock_transition -fall  50 ${CLOCK_NAME}


# Define JTAG clock
create_clock -domain domain2 -name tck -period 100000 [get_db ports tck]
set_false_path -from [get_clocks ${CLOCK_NAME}] -to [get_clocks tck]
set_false_path -from [get_clocks tck] -to [get_clocks ${CLOCK_NAME}]

set all_regs [get_db insts -if .is_sequential]
define_cost_group -name C2C
path_group -from $all_regs -to $all_regs -group C2C -name C2C

# Set Input and output Delay
# set_input_delay  [expr 0.3 * ${CLOCK_PERIOD_ps}] -clock ${CLOCK_NAME} [all_inputs -no_clock]
# set_output_delay [expr 0.3 * ${CLOCK_PERIOD_ps}] -clock ${CLOCK_NAME} [all_outputs]

# Disable timing paths for GPIO async input ports up to register ports
# set_false_path -from [get_ports GPIO_ASYNC_IN] -to [get_nets -hierarchical gpio/gpio_reg*]


####################################################################################################
## Synthesizing to generic 
####################################################################################################

set_db syn_generic_effort $GEN_EFF
syn_generic

write_snapshot -directory ${_REPORTS_PATH}/generic -tag generic
report_dp > ${_REPORTS_PATH}/generic/${DESIGN}_datapath.rpt
report_summary -directory ${_REPORTS_PATH}





####################################################################################################
## Synthesizing to gates
####################################################################################################


set_db syn_map_effort $MAP_OPT_EFF
syn_map

write_snapshot -directory ${_REPORTS_PATH}/map -tag map
report_dp > ${_REPORTS_PATH}/map/${DESIGN}_datapath.rpt
report_summary -directory ${_REPORTS_PATH}



#######################################################################################################
## Optimize Netlist
#######################################################################################################

set_db syn_opt_effort $MAP_OPT_EFF
syn_opt



write_snapshot -directory ${_REPORTS_PATH}/opt -tag syn_opt
report_dp > ${_REPORTS_PATH}/opt/${DESIGN}_datapath.rpt
report_summary -directory ${_REPORTS_PATH}


#######################################################################################################
## Export Design Files
#######################################################################################################

write_snapshot -directory ${_REPORTS_PATH}/final -tag final
report_summary -directory ${_REPORTS_PATH}

write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_synth.v
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_synth.sdc
write_sdf > ${_OUTPUTS_PATH}/${DESIGN}_synth.sdf
write_script > ${_OUTPUTS_PATH}/${DESIGN}.script

write_design -base_name ${_OUTPUTS_PATH}/DESIGN/${DESIGN}_synth
write_db -all_root_attributes -script ${_OUTPUTS_PATH}/DESIGN/${DESIGN}_synth.tcl    


#######################################################################################################
## Write Reports
#######################################################################################################

report_qor > ${_REPORTS_PATH}/${DESIGN}_qor.rpt
report_area > ${_REPORTS_PATH}/${DESIGN}_area.rpt
report_dp > ${_REPORTS_PATH}/${DESIGN}_datapath_incr.rpt
report_messages > ${_REPORTS_PATH}/${DESIGN}_messages.rpt
report_gates > ${_REPORTS_PATH}/${DESIGN}_gates.rpt
report_timing > ${_REPORTS_PATH}/${DESIGN}_timing.rpt
report_power > ${_REPORTS_PATH}/${DESIGN}_power.rpt


#######################################################################################################
## Write LEC
#######################################################################################################

## Write LEC script comparing the synthesized design with the original RTL.
write_do_lec -revised_design ${_OUTPUTS_PATH}/${DESIGN}_synth.v -logfile ${_OUTPUTS_PATH}/rtl2final.lec.log > ${_OUTPUTS_PATH}/rtl2final.lec.do


#######################################################################################################
## DFT Flow
#######################################################################################################


# source genus_dft_flow.tcl



#######################################################################################################
## END
#######################################################################################################
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

# add_tieoffs
