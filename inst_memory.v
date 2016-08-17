module inst_memory(stall, data_stall, clk, reset, addr, target_enable, mod_inst, mod_pc, true_taken, inst, inst_cache_stall, pc_count, pre_target_enable, pre_target);
  
  input stall, data_stall, clk, reset, addr, target_enable, mod_inst, mod_pc, true_taken;
  output inst, inst_cache_stall, pc_count, pre_target_enable, pre_target;
  
  reg [31:0] pc_count;
  
  reg [7:0] inst_memoryc[0:1023]; 
  
  wire [31:0] addr, L1_addr, L2_addr, L3_addr, Mem_addr;
  
  wire [31:0] L1_wdata, L2_wdata, L3_wdata, Mem_wdata;
  wire L1_wenable, L2_wenable, L3_wenable, Mem_wenable;
  wire L1_stall, L2_stall, L3_stall;
  reg Mem_stall;
  
  wire [0:511] L1_block;
  wire [0:1023] L2_block;
  reg [0:2047] L3_block;

  integer i;

  assign L1_addr = addr;
  
  reg [31:0] inst;  
  wire [31:0] word;
  
  wire renable1, renable2, renable3;
  
  wire [31:0] mod_inst, mod_pc, pre_target;
  wire true_taken, pre_target_enable;
  
  branch_predictor predictor (pc_count, inst, mod_inst, mod_pc, true_taken, clk, pre_target_enable, pre_target); 
  
  assign inst_cache_stall = L1_stall;
  
  L1_cache L1 (clk, !reset, L1_addr, L1_wdata, L1_wenable, L1_block, L2_stall, L1_stall, word,     L2_addr, L2_wdata, L2_wenable, renable1);
  L2_cache L2 (clk, renable1, L2_addr, L2_wdata, L2_wenable, L2_block, L3_stall, L2_stall, L1_block, L3_addr, L3_wdata, L3_wenable, renable2);
  L3_cache L3 (clk, renable2, L3_addr, L3_wdata, L3_wenable, L3_block, Mem_stall, L3_stall, L2_block, Mem_addr, Mem_wdata, Mem_wenable, renable3);
  
  always @(posedge target_enable)
  begin
    inst <= 32'b0;
  end
  
  always @(posedge clk)
  begin
    if (!data_stall & stall !== 1)
    begin 
      if (!inst_cache_stall)
      begin
        inst <= word;
        pc_count <= addr;
      end
      else
      begin
        inst <= 32'b0;
      end
    end
  end

  always @(renable3 or Mem_addr)
  begin
    if (renable3)
    begin
      Mem_stall = 1;
      if (Mem_wenable)
      begin
        {inst_memoryc[Mem_addr], inst_memoryc[Mem_addr + 1], inst_memoryc[Mem_addr + 2], inst_memoryc[Mem_addr + 3]} <= Mem_wdata;
      end
      //L3_block <= inst_memoryc[addr +: 256];
      for (i =  0; i < 256;  i = i + 1)
      begin
        L3_block[i << 3 +: 8] = inst_memoryc[{Mem_addr[31:8],i[7:0]}];
      end
      Mem_stall <= 0;
    end
  end
  
  
   
  initial
  begin
    Mem_stall <= 0;
    $readmemh("program.txt", inst_memoryc);
  end
  
endmodule


