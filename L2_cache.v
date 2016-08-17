`timescale 10ns/10ns

module L2_cache(clk, renable, addr, wdata, wenable, L2_block, L3_stall, cache_stall, data, L3_addr, L3_wdata, L3_wenable, L3_renable);
  
  input clk, addr, renable, wdata, wenable, L2_block, L3_stall;
  output cache_stall, data, L3_addr, L3_wdata, L3_wenable, L3_renable;
  
  wire[31:0] addr, wdata;
  reg[0:511] data;
  wire clk, wenable;
  reg cache_stall, latency;

  parameter L3_lantency = 10;

  reg[0:511] cdata[0:63][0:1];
  reg[16:0] ctag[0:63];
  reg valid[0:63];

  wire[5:0] offset = addr[5:0];
  wire  offset1 = addr[6];
  wire[7:0] index = addr[14:7];
  wire[16:0] tag = addr[31:15];
  
  wire[0:1023] L2_block;
  wire L3_stall;
  reg[31:0] L3_addr, L3_wdata;
  reg L3_wenable, L3_renable;
  integer i;
  
  
  //L3 L3_cache(clk, L3_addr, L3_wdata, L3_wenable, L3_stall, L2_block);
  
  always @(renable or L3_stall or addr)
  begin
    if (renable & L3_stall !== 1)
    begin
      if (cache_stall)
      begin
        if (!latency)
        begin
          latency <= 1;
          #L3_lantency 
          begin
            cache_stall <= 0;
            valid[index] <= 1;
            ctag[index] <= tag;
            cdata[index][0] = L2_block[0:511];
            cdata[index][1] = L2_block[512:1023];
            data <= cdata[index][offset1];
            latency <= 0;
            L3_renable <= 0;
            L3_wenable <= 0;
          end
        end
      end
      else
      begin
        if (wenable)
        begin
          //write through
          L3_addr <= addr;
          L3_wenable <= 1;
          L3_renable <= 1;
          L3_wdata <= wdata;
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
            L3_addr <= addr;
            L3_wenable <= 0;
            L3_renable <= 1;
          end
        end
      end
    end
  end
  
  initial
  begin
    cache_stall <= 0;
    latency <= 0;
    L3_renable <= 0;
    for (i = 0; i < 64; i = i + 1)
    begin
      valid[i] <= 0;
    end
  end
endmodule


