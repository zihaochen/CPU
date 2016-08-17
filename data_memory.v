module data_memory(clk, addr, inst, result, data_cache_stall, inst2, wback);
  
  input clk, addr, inst, result;
  output data_cache_stall, inst2, wback;
  
  wire data_cache_stall;
  
  wire [31:0] addr, inst, result;
  
  reg [31:0] inst2, wback;
  
  reg [7:0] data_memoryc[0:1023];
   
  reg [31:0] L1_addr, L1_wdata;
   
  wire [31:0] L2_addr, L3_addr, Mem_addr;
  
  wire [31:0] L2_wdata, L3_wdata, Mem_wdata;
  wire L2_wenable, L3_wenable, Mem_wenable;
  wire L1_stall, L2_stall, L3_stall;
  reg Mem_stall;
  
  wire [0:511] L1_block;
  wire [0:1023] L2_block;
  reg [0:2047] L3_block;

  integer i;

  wire [31:0] word;
  
  wire  renable1, renable2, renable3;
  reg renable0, L1_wenable;
  
  L1_cache L1 (clk, renable0, L1_addr, L1_wdata, L1_wenable, L1_block, L2_stall, L1_stall, word,     L2_addr, L2_wdata, L2_wenable, renable1);
  L2_cache L2 (clk, renable1, L2_addr, L2_wdata, L2_wenable, L2_block, L3_stall, L2_stall, L1_block, L3_addr, L3_wdata, L3_wenable, renable2);
  L3_cache L3 (clk, renable2, L3_addr, L3_wdata, L3_wenable, L3_block, Mem_stall, L3_stall, L2_block, Mem_addr, Mem_wdata, Mem_wenable, renable3);
  
  assign data_cache_stall = L1_stall;
  /*
  always @(word)
  begin
    if (inst[31:26] == 6'b100011)
    begin
      wback <= word;
    end
  end
  */
  always @(posedge clk)
  begin
    if (!L1_stall)
    begin
      inst2 <= inst;
      case(inst[31:26])
        6'b100011 : wback <= word;
        default : wback <= addr;
      endcase
    end
  end
  
  always @(addr or inst or result)
  begin
    if (!data_cache_stall)
    begin
      case(inst[31:26])
        6'b100011 : 
        begin
          renable0 <= 1;
          L1_addr <= addr;
        end
        6'b101011 : 
        begin
          renable0 <= 1;
          L1_wenable <= 1;
          L1_addr <= addr;
          L1_wdata <= result;
        end
        default : 
        begin
          renable0 <= 0;
          L1_wenable <= 0;
        end
      endcase
    end
  end

  always @(renable3 or Mem_addr)
  begin
    if (renable3)
    begin
      Mem_stall = 1;
      if (Mem_wenable)
      begin
        {data_memoryc[Mem_addr], data_memoryc[Mem_addr + 1], data_memoryc[Mem_addr + 2], data_memoryc[Mem_addr + 3]} <= Mem_wdata;
      end
      for (i =  0; i < 256;  i = i + 1)
      begin
        L3_block[i << 3 +: 8] = data_memoryc[{Mem_addr[31:8],i[7:0]}];
      end
      Mem_stall <= 0;
    end
  end
  
  initial
  begin
    renable0 <= 0;
    Mem_stall <= 0;
    //$readmemb("DMEM.txt", data_memoryc);
    for (i = 0; i <= 100; i = i + 1)
    begin
      {data_memoryc[i * 4], data_memoryc[i * 4 + 1], data_memoryc[i * 4 + 2], data_memoryc[i * 4 + 3]} = i + 1;
    end
  end

  
endmodule




