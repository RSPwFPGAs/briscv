read_verilog [glob ../../src/*.v]
read_xdc synth_area.xdc

synth_design -part xcku040-ffva1156-2-e -top briscv_1c 
opt_design -sweep -propconst -resynth_seq_area
opt_design -directive ExploreSequentialArea

report_utilization
report_timing

