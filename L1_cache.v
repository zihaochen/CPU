`timescale 10ns/10ns

module L1_cache(clk, renable, addr, wdata, wenable, L1_block, L2_stall, cache_stall, data, L2_addr, L2_wdata, L2_wenable, L2_renable);
  
  input clk, addr, renable, wdata, wenable, L1_block, L2_stall;
  output cache_stall, data, L2_addr, L2_wdata, L2_wenable, L2_renable;
  
  wire[31:0] addr, wdata;
  reg[31:0] data;
  wire clk, wenable;
  reg cache_stall, latency;

  parameter L2_lantency = 4;

  reg[7:0] cdata[0:255][0:63];
  reg[17:0] ctag[0:255];
  reg valid[0:255];

  wire[5:0] offset = addr[5:0];
  wire[7:0] index = addr[13:6];
  wire[17:0] tag = addr[31:14];
  
  wire[0:511] L1_block;
  wire L2_stall;
  reg[31:0] L2_addr, L2_wdata;
  reg L2_wenable, L2_renable;
  integer i;
  
  
  //L2 L2_cache(clk, L2_addr, L2_wdata, L2_wenable, L2_stall, L1_block);
  
  always @(renable or L2_stall or addr)
  begin
    if (renable & L2_stall !== 1)
    begin
      if (cache_stall)
      begin
        if (!latency)
        begin
          latency <= 1;
          #L2_lantency 
          begin
            cache_stall <= 0;
            valid[index] <= 1;
            ctag[index] <= tag;
            for (i = 0; i < 64; i = i + 1)
            begin
              cdata[index][i] = L1_block[i << 3 +: 8];
            end
            data <= {cdata[index][offset], cdata[index][offset + 1], cdata[index][offset + 2], cdata[index][offset + 3]};
            latency <= 0;
            L2_renable <= 0;
            L2_wenable <= 0;
          end
        end
      end
      else
      begin
        if (wenable)
        begin
          //write through
          L2_addr <= addr;
          L2_wenable <= 1;
          L2_renable <= 1;
          L2_wdata <= wdata;
          if (valid[index] & ctag[index] == tag)
          begin
            {cdata[index][offset], cdata[index][offset + 1], cdata[index][offset + 2], cdata[index][offset + 3]} <= wdata;
          end
          cache_stall <= 1;
        end
        else
        begin
          if (valid[index] & ctag[index] == tag)
          begin
            data <= {cdata[index][offset], cdata[index][offset + 1], cdata[index][offset + 2], cdata[index][offset + 3]};
          end
          else
          begin
            cache_stall <= 1;
            L2_renable <= 1;
            L2_addr <= addr;
            L2_wenable <= 0;
          end
        end
      end
    end
  end
  
  initial
  begin
    cache_stall <= 0;
    latency <= 0;
    L2_renable <= 0;
    for (i = 0; i < 256; i = i + 1)
    begin
      valid[i] <= 0;
    end
  end
endmodule
