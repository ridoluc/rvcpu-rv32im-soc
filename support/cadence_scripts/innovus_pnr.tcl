####################################################################
##
##          INNOVUS PnR FLOW SCRIPT
## 
####################################################################


####################################################################
## Design Variables Setup
####################################################################

#Top-level module name
set DESIGN TOP  
set VERILOG_FILES [list DATA/TOP.v DATA/SYSTEM_TOP_synth.v]
set SDC_FILE DATA/SYSTEM_TOP_synth.sdc
set IO_FILE DATA/chip_pads.io

# Set Floorplan parameters
# The gap between the core and the padring is expressed in um
set CORE_ASPECT_RATIO 1.0
set CORE_UTILIZATION 0.6        
set COREGAP 30  

# Set Power Ring parameters (in um)
# The power ring is a rectangular area around the core that provides power and ground connections.
# -width: Width of the wires
# -spacing: Spacing between the wires
# -offset: Offset from the core boundary
set POWER_RING_WIDTH 6
set POWER_RING_SPACING 3
set POWER_RING_OFFSET 1


####################################################################
## Environment Setup
####################################################################

set init_verilog ${VERILOG_FILES}
set init_top_cell ${DESIGN}
set init_lef_file { \
    /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/lef/tcbn65lpbwp7t_141a/lef/tcbn65lpbwp7t_9lmT2.lef \
    /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/lef/tphn65lpnv2od3_sl_200b/mt_2/9lm/lef/tphn65lpnv2od3_sl_9lm.lef \
    /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/lef/tpbn65v_200b/wb/9m/9M_6X2Z/lef/tpbn65v_9lm.lef \
    /ibe/users/lr524/SRAM_LICENCE/tsdn65lplla1024x32m4m_200a/LEF/tsdn65lplla1024x32m4m_200a_5m.lef \
    /ibe/users/lr524/SRAM_LICENCE/ts1n65lpll256x32m4_220a/LEF/ts1n65lpll256x32m4_220a_5m.lef \
    /ibe/users/lr524/RVCPU/scripts/PLL_25M_400M.lef
    }
set init_mmmc_file "./DATA/mmmc_timing.tcl"

set init_gnd_net {VSS}
set init_pwr_net {VDD}


set init_io_file ${IO_FILE}


setDesignMode -process 65

init_design

setDesignMode -topRoutingLayer 7


#####################################################################
## Floorplan Setup  
#####################################################################
floorplan -r ${CORE_ASPECT_RATIO} ${CORE_UTILIZATION} ${COREGAP} ${COREGAP} ${COREGAP} ${COREGAP} 


## Place instance blocks
placeInstance SoC/pll 610 715
placeInstance SoC/instruction_memory_instruction_memory 610 150 R180
placeInstance SoC/ram_ram 610 600


## IO Pads filler
addIoFiller -cell {PFILLER0005 PFILLER05 PFILLER1 PFILLER5 PFILLER10 PFILLER20} -prefix FILLER -side n
addIoFiller -cell {PFILLER0005 PFILLER05 PFILLER1 PFILLER5 PFILLER10 PFILLER20} -prefix FILLER -side e
addIoFiller -cell {PFILLER0005 PFILLER05 PFILLER1 PFILLER5 PFILLER10 PFILLER20} -prefix FILLER -side w
addIoFiller -cell {PFILLER0005 PFILLER05 PFILLER1 PFILLER5 PFILLER10 PFILLER20} -prefix FILLER -side s

globalNetConnect VSS -type pgpin -pin VSS -all -override
globalNetConnect VDD -type pgpin -pin VDD -all -override
globalNetConnect VDD -type tiehi -pin VDD -all -override
globalNetConnect VSS -type tielo -pin VSS -all -override


addRing -width ${POWER_RING_WIDTH} -spacing ${POWER_RING_SPACING} -offset ${POWER_RING_OFFSET} -layer {top M1 bottom M1 left M2 right M2} -center 1 -nets { VSS VDD }

## Add power ring and halo around each macro block if needed
addRing -around each_block -type block_rings -width 3 -spacing 2 -offset 1 -layer {top M1 bottom M1 left M2 right M2} -nets { VSS VDD }
addHaloToBlock -allBlock 10 10 10 10

# Special routing for power and ground nets
sroute -nets { VSS VDD} -allowJogging true -allowLayerChange true -blockPin useLef -connect {blockPin padPin padRing corePin floatingStripe }

addStripe  -nets {VDD VSS} -layer 6 -width 6 -spacing 3 -start 50 -set_to_set_distance 100 -direction vertical -area_blockage {{610 600 787 682} {610 150 916 355} {610 715 914 909}}


## Pin placement
# editPin -side LEFT -layer M3 -fixedPin 1 -spreadType CENTER -spacing 2 -pin { clk rst_n}
# editPin -side BOTTOM -layer M3 -fixedPin 1 -spreadType CENTER -spacing 2 -pin { out* }

##  End cap placement [cant see the cells in the library]
# setEndCapMode -leftEdge ENDCAPL -rightEdge ENDCAPR
# addEndCap -prefix ENDCAP
addWellTap -cell TAPCELLBWP7T -prefix welltap -cellInterval 60 -checkerBoard

# Define the scan chain
specifyScanChain scan_chain -start pad_scan_di -stop pad_scan_do
setScanReorderMode -compLogic true
scanTrace -lockup -verbose


timeDesign -prePlace -expandedViews -outDir ./REPORTS/prePlace -prefix prePlace



####################################################################
## Placement 
####################################################################


setPlaceMode -timingDriven true -congEffort auto  
# -place_global_place_io_pins true 
place_opt_design 

setTieHiLoMode -maxFanout 10 -maxDistance 50
addTieHiLo -cell "TIEHBWP7T TIELBWP7T" 

timeDesign -preCTS -outDir REPORTS/preCTS -prefix preCTS


#Automatically assign the IO pins to the design
# assignIoPins -pin *

saveDesign ./SAVES/${DESIGN}_postPlace.enc

####################################################################
## Clock Tree Synthesis 
####################################################################

## OPTIONAL
# add_ndr -name default_2x_space -spacing {MET1 1 MET2:MET4 1.5}
# create_route_type -name leaf_rule  -non_default_rule default_2x_space -top_preferred_layer MET4 -bottom_preferred_layer MET2
# create_route_type -name trunk_rule -non_default_rule default_2x_space -top_preferred_layer MET4 -bottom_preferred_layer MET2 -shield_net GND -shield_side both_side
# create_route_type -name top_rule   -non_default_rule default_2x_space -top_preferred_layer MET4 -bottom_preferred_layer MET2 -shield_net GND -shield_side both_side
# set_ccopt_property route_type -net_type leaf  leaf_rule
# set_ccopt_property route_type -net_type trunk trunk_rule
# set_ccopt_property route_type -net_type top   top_rule


set_ccopt_property buffer_cells {CKBD0BWP7T CKBD1BWP7T CKBD2BWP7T CKBD3BWP7T CKBD4BWP7T CKBD6BWP7T CKBD8BWP7T CKBD10BWP7T CKBD12BWP7T}
set_ccopt_property inverter_cells {CKND0BWP7T CKND1BWP7T CKND2BWP7T CKND3BWP7T CKND4BWP7T CKND6BWP7T CKND8BWP7T CKND10BWP7T CKND12BWP7T}


## OPTIONAL
## CHECK the values (more here: http://www.ids.uni-bremen.de/lectures/lab_ic/2_tut_intermediate_cts_floorplan/#orga80ee61)
set_ccopt_property target_max_trans 130ps 
set_ccopt_property target_skew 200ps
set_ccopt_property max_fanout 20

setOptMode -usefulSkew true
setOptMode -usefulSkewCCOpt extreme

create_ccopt_clock_tree_spec -file REPORTS/ctsspec.tcl
source REPORTS/ctsspec.tcl
ccopt_design -check_prerequisites
ccopt_design

optDesign -postCTS -setup -hold -outDir REPORTS/postCTSOptTiming
timeDesign -postCTS -expandedViews -outDir REPORTS/postCTS -prefix postCTS
report_ccopt_clock_trees -file REPORTS/postCTS/clock_trees.rpt
report_ccopt_skew_groups -file REPORTS/postCTS/skew_groups.rpt

saveDesign ./SAVES/${DESIGN}_postCTS.enc


####################################################################
## Routing 
####################################################################

routeDesign 

## Set analysis on on-chip variation (OCV) mode 
setAnalysisMode -analysisType onChipVariation -skew true -clockPropagation sdcControl
optDesign -postRoute -setup
optDesign -postRoute -hold


## Saving the design
saveDesign ./SAVES/${DESIGN}_postRoute.enc

####################################################################
## Signoff 
####################################################################


addFiller -cell {FILL1BWP7T FILL2BWP7T FILL4BWP7T FILL8BWP7T FILL16BWP7T FILL32BWP7T FILL64BWP7T} -doDRC

verifyConnectivity
verify_drc -limit 100000


timeDesign -postRoute -expandedViews -outDir REPORTS/postRoute -prefix postRoute


## Saving the design
saveDesign ./SAVES/${DESIGN}_done.enc


####################################################################
## Export Design
####################################################################

## Export final netlist to Verilog format
saveNetlist OUTPUTS/[format "%s_soc.v" $DESIGN]

## Export delay information to SDF format
write_sdf OUTPUTS/${DESIGN}.sdf 

## Exporting the design to LEF format
write_lef_abstract OUTPUTS/${DESIGN}.lef -stripePin

# Builds a Liberty (.lib) format model for the top cell, which is the timing model
do_extract_model OUTPUTS/${DESIGN}.lib  -view functional_typ

## Export parasitics to SPEF format
extractRC -outfile ${DESIGN}.cap
rcOut -spef OUTPUTS/${DESIGN}.spef

## Exporting the design to GDSII format
streamOut OUTPUTS/${DESIGN}.gds -structureName ${DESIGN} \
                                -mode ALL  \
                                -attachInstanceName 13 -attachNetName 13 \
                                -dieAreaAsBoundary \
                                -merge { \
                                    /ibe/users/lr524/SRAM_LICENCE/ts1n65lpll256x32m4_220a/GDSII/ts1n65lpll256x32m4_220a.gds\
                                    /ibe/users/lr524/SRAM_LICENCE/tsdn65lplla1024x32m4m_200a/GDSII/tsdn65lplla1024x32m4m_200a.gds \
                                    /ibe/users/lr524/PLL_25M_400M.gds \
                                    } \
                                -mapFile "/ibe/users/lr524/RVCPU/scripts/gds2.map"

# restoreDesign SAVES/TOP_done.enc.dat TOP

#  \
# /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/gds/tcbn65lpbwp7t_141a/tcbn65lpbwp7t.gds \
# /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/gds/tphn65lpnv2od3_sl_200b/mt_2/9lm/tphn65lpnv2od3_sl.gds\
# /ibe/local/cadence/kits/tsmc/beLibs/65nm/TSMCHOME/digital/Back_End/gds/tpbn65v_200b/cup/9m/9M_6X2Z/tpbn65v.gds\
# /ibe/users/lr524/TEST_DIGITAL/DUMMY_PLL/LAYOUT/OUTPUTS/Divider.gds


####################################################################
## Other Operations 
####################################################################

######## Reports
# verify_drc         > ./REPORTS/postRoute/${DESIGN}_done_drc.rep
# verifyConnectivity > ./REPORTS/postRoute/${DESIGN}_done_connectivity.rep
# verifyGeometry     > ./REPORTS/postRoute/${DESIGN}_done_geometry.rep
# verifyPowerVia     > ./REPORTS/postRoute/${DESIGN}_done_powerVia.rep


########   Retrieving the design
#  restoreDesign filename.enc.dat top_cell_name


########   Add metal fill to increase the density of the design.
# setMetalFill -layer METAL2 -windowSize 10 10 -windowStep 5 5
# addMetalFill

########   Fixing DRC violations
########   delete the routing of the nets with violations and re-route them
# editDelete -regular_wire_with_drc
# routeDesign
# verify_drc -limit 10000

## Delete top Layers and re route after setting top preferred layer
# setDesignMode -topRoutingLayer 7
# editDelete -layer {M7 M8 M9}
# editDelete -floating_via

# setNanoRouteMode -drouteFixAntenna true
# setNanoRouteMode -routeAntennaDiodeCellName "ANTENNA"
# setNanoRouteMode -routeInsertAntennaDiode true



#Creates  a  clock tree network with associated skew groups and other clock tree synthesis
#       Note: You can execute the file only once. If you run the above again, the software
#       gives an error message:

#       source spec.tcl

#       Cannot run clock tree spec: clock trees are already defined.

#       The already loaded specification file can be removed by using either of  the  fol-
#       lowing commands:

#       * delete_ccopt_clock_tree_spec

#       * reset_ccopt_config



## Create group for analog power domain

# createInstGroup pll_group -fence 750 850 950 945
# addInstToInstGroup pll_group SoC/dummy_pll

# selectObject Group pll_group




# *** Finished refinePlace (0:14:03 mem=1970.8M) ***
# *** maximum move = 1.60 um ***
# *** Finished re-routing un-routed nets (1970.8M) ***
# **ERROR: (IMPESI-2221): No driver PLL_OUT/PAD is found in the delay stage for net pad_pll_out.
# **ERROR: (IMPESI-2221): No driver PLL_CLK_IN/XO is found in the delay stage for net pad_pll_clk_o.
# **ERROR: (IMPESI-2221): No driver PLL_CTRL_0/PAD is found in the delay stage for net pad_pll_select[0].
# **ERROR: (IMPESI-2221): No driver PLL_CTRL_1/PAD is found in the delay stage for net pad_pll_select[1].
# **ERROR: (IMPESI-2221): No driver PLL_CTRL_2/PAD is found in the delay stage for net pad_pll_select[2].
# **ERROR: (IMPESI-2221): No driver PLL_CTRL_3/PAD is found in the delay stage for net pad_pll_select[3].
# **ERROR: (IMPESI-2221): No driver SCAN_DO/PAD is found in the delay stage for net pad_scan_do.
# **ERROR: (IMPESI-2221): No driver SCAN_DI/PAD is found in the delay stage for net pad_scan_di.
# **ERROR: (IMPESI-2221): No driver SCAN_TSTMD/PAD is found in the delay stage for net pad_scan_testmode.
# **ERROR: (IMPESI-2221): No driver SCAN_EN/PAD is found in the delay stage for net pad_scan_en.
# **ERROR: (IMPESI-2221): No driver UART_RX/PAD is found in the delay stage for net pad_uart_rx.
# **ERROR: (IMPESI-2221): No driver UART_TX/PAD is found in the delay stage for net pad_uart_tx.
# **ERROR: (IMPESI-2221): No driver GPIO_0/PAD is found in the delay stage for net pad_gpio[0].
# **ERROR: (IMPESI-2221): No driver GPIO_1/PAD is found in the delay stage for net pad_gpio[1].
# **ERROR: (IMPESI-2221): No driver GPIO_2/PAD is found in the delay stage for net pad_gpio[2].
# **ERROR: (IMPESI-2221): No driver GPIO_3/PAD is found in the delay stage for net pad_gpio[3].
# **ERROR: (IMPESI-2221): No driver GPIO_4/PAD is found in the delay stage for net pad_gpio[4].
# **ERROR: (IMPESI-2221): No driver GPIO_5/PAD is found in the delay stage for net pad_gpio[5].
# **ERROR: (IMPESI-2221): No driver GPIO_6/PAD is found in the delay stage for net pad_gpio[6].
# **ERROR: (IMPESI-2221): No driver GPIO_7/PAD is found in the delay stage for net pad_gpio[7].


# **ERROR: (IMPOPT-6080): AAE-SI Optimization can only be turned on when the timing analysis mode is set to OCV.

# **WARN: (IMPSP-5217):   addFiller command is running on a postRoute database. It is recommended to be followed by ecoRoute -target command to make the DRC clean.



# Power Analysis

# set_power_output_dir -reset
# set_power_output_dir ./REPORTS/POWER
# read_activity_file -reset
# set_switching_activity -clock clk -scale_factor 2.5
# read_activity_file -format VCD -scope CPU_tb/dut -start 311000 -end 411900 -block {} SIM/waveform.vcd
# set_power -reset
# set_powerup_analysis -reset
# set_dynamic_power_simulation -reset
# report_power -rail_analysis_format VS -outfile REPORTS/POWER/TOP.rpt