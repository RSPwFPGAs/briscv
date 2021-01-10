rm briscv_1c*; iverilog -o briscv_1c ../../src/*.v; vvp -n briscv_1c +vcd
