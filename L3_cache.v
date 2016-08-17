`timescale 10ns/10ns

module L3_cache(clk, renable, addr, wdata, wenable, L3_block, Mem_stall, cache_stall, data, Mem_addr, Mem_wdata, Mem_wenable, Mem_renable);
  
  input clk, addr, renable, wdata, wenable, L3_block, Mem_stall;
  output cache_stall, data, Mem_addr, Mem_wdata, Mem_wenable, Mem_renable;
  
  wire[31:0] addr, wdata;
  reg[0:1023] data;
  wire clk, wenable;
  reg cache_stall, latency;

  parameter Mem_lantency = 400;

  reg[0:1023] cdata[0:63][0:1];
  reg[16:0] ctag[0:63];
  reg valid[0:63];

  wire[6:0] offset = addr[6:0];
  wire  offset1 = addr[7];
  wire[7:0] index = addr[15:8];
  wire[16:0] tag = addr[31:16];
  
  wire[0:2047] L3_block;
  reg[31:0] Mem_addr, Mem_wdata;
  reg Mem_wenable, Mem_renable;

  integer i;
  
  always @(renable or addr or Mem_stall)
  begin
    if (renable & Mem_stall !== 1)
    begin
    if (cache_stall)
    begin
      if (!latency)
      begin
        latency <= 1;
        Mem_renable <= 0;
        Mem_wenable <= 0;
        #Mem_lantency 
        begin
          cache_stall <= 0;
          valid[index] <= 1;
          ctag[index] <= tag;
          cdata[index][0] = L3_block[0:1023];
          cdata[index][1] = L3_block[1024:2047];
          data <= cdata[index][offset1];
          latency <= 0;
        end
      end
    end
    else
    begin
      if (wenable)
      begin
        //write through
        Mem_addr <= addr;
        Mem_wenable <= 1;
        Mem_renable <= 1;
        Mem_wdata <= wdata;
        if (valid[index] & ctag[index] == tag)
        begin
          {cdata[index][offset1][offset << 3 +: 32]} <= wdata;
        end
        cache_stall <= 1;
      end
      else
      begin
        if (valid[index] & ctag[index] == tag)
        begin
          cache_stall = 1;
          data <= cdata[index][offset1];
          cache_stall <= 0;
        end
        else
        begin
          cache_stall <= 1;
          Mem_addr <= addr;
          Mem_wenable <= 0;
          Mem_renable <= 1;
        end
      end 
    end
    end
  end
  
  
  initial
  begin
    cache_stall <= 0;
    latency <= 0;
    Mem_renable <= 0;
    for (i = 0; i < 64; i = i + 1)
    begin
      valid[i] <= 0;
    end
  end  
endmodule



