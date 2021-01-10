`ifndef PROC_BRAM_MACROS
  `define PROC_BRAM_MACROS 1
  //`define PROGRAM_BRAM_MEMORY dut.memory.BYTE_LOOP[0].BRAM_byte.ram
  `define PROGRAM_BRAM_MEMORY FIXME // used in cache top
  `define REGISTER_FILE dut.core.ID.registers.register_file
  `define CURRENT_PC dut.core.FI.PC_reg
`endif

module tb_briscv_1c();

parameter CORE             = 0;
parameter DATA_WIDTH       = 32;
parameter ADDRESS_BITS     = 32;
parameter MEM_ADDRESS_BITS = 10;
parameter SCAN_CYCLES_MIN  = 0;
parameter SCAN_CYCLES_MAX  = 1000;
parameter PROGRAM          = "<PROGRAM PATH HERE>";
parameter TEST_NAME        = "<PROGRAM 1 NAME HERE>";
parameter LOG_FILE         = "briscv_1c.log";

genvar byte;
integer x;
integer log_file;

reg clock;
reg reset;
reg start;
reg [ADDRESS_BITS-1:0] program_address;

wire [ADDRESS_BITS-1:0] PC;

reg scan;

// Single reg to load program into before splitting it into bytes in the
// byte enabled dual port BRAM
reg [DATA_WIDTH-1:0] dummy_ram [2**MEM_ADDRESS_BITS-1:0];

briscv_1c #(
  .CORE(CORE),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_BITS(ADDRESS_BITS),
  .MEM_ADDRESS_BITS(MEM_ADDRESS_BITS),
  .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
  .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
) dut (
  .clock(clock),
  .reset(reset),
  .start(start),
  .program_address(program_address),
  .PC(PC),
  .scan(scan)
);


// Clock generator
always #1 clock = ~clock;

// Initialize program memory
initial begin
  for(x=0; x<2**MEM_ADDRESS_BITS; x=x+1) begin
    dummy_ram[x] = {DATA_WIDTH{1'b0}};
  end
  for(x=0; x<32; x=x+1) begin
    `REGISTER_FILE[x] = 32'd0;
  end
  $readmemh(PROGRAM, dummy_ram);
end

generate
for(byte=0; byte<DATA_WIDTH/8; byte=byte+1) begin : BYTE_LOOP
  initial begin
    #1 // Wait for dummy ram to be initialzed
    // Copy dummy ram contents into each byte BRAM
    for(x=0; x<2**MEM_ADDRESS_BITS; x=x+1) begin
      dut.memory.memory.BYTE_LOOP[byte].BRAM_byte.ram[x] = dummy_ram[x][8*byte +: 8];
    end
  end
end
endgenerate


integer start_time;
integer end_time;
integer total_cycles;

initial begin
  clock  = 1;
  reset  = 1;
  scan = 0;
  start = 0;
  program_address = {ADDRESS_BITS{1'b0}};
  #10

  #1
  reset = 0;
  start = 1;
  start_time = $time;
  #1

  start = 0;

  log_file = $fopen(LOG_FILE,"a+");
  if(!log_file) begin
    $display("Could not open log file... Exiting!");
    $finish();
  end


end

always begin

  // Check pass/fail condition every 1000 cycles so that check does not slow
  // down simulation to much
  #1
  if(`CURRENT_PC == 32'h000000b0 || `CURRENT_PC == 32'h000000b4) begin
    end_time = $time;
    total_cycles = (end_time - start_time)/2;
    #100 // Wait for pipeline to empty
    $display("\nRun Time (cycles): %d", total_cycles);
    $fdisplay(log_file, "\nRun Time (cycles): %d", total_cycles);
    if(`REGISTER_FILE[9] == 32'h0000000) begin
      $display("%s:\nTest Passed!\n\n", TEST_NAME);
      $fdisplay(log_file, "%s:\nTest Passed!\n\n", TEST_NAME);
    end else begin
      $display("%s:\nTest Failed!\n\n", TEST_NAME);
      $fdisplay(log_file,"%s:\nTest Failed!\n\n", TEST_NAME);
      $display("Dumping reg file states:");
      $fdisplay(log_file,"Dumping reg file states:");
      $display("Reg Index, Value");
      $fdisplay(log_file,"Reg Index, Value");
      for( x=0; x<32; x=x+1) begin
        $display("%d: %h", x, `REGISTER_FILE[x]);
        $fdisplay(log_file, "%d: %h", x, `REGISTER_FILE[x]);
      end
      $display("");
      $fdisplay(log_file, "");
    end // pass/fail check

    $fclose(log_file);
    $stop();

  end // pc check
end // always

endmodule
