module program_counter(stall, clk, target, target_enable, pre_target, pre_target_enable, reset, pc_count);
  
  input clk, reset, stall, target, target_enable, pre_target, pre_target_enable;
  output pc_count;
  
  wire clk, reset, target_enable;
  
  wire[31:0] target, pre_target;
  
  reg[31:0] pc_count;
  
  always @(pre_target_enable or pre_target)
  begin
    if (pre_target_enable)
    begin
      pc_count <= pre_target;
    end
  end

  always @(target_enable or target)
  begin
    if (target_enable)
    begin
      pc_count <= target;
    end
  end
  
  always @(posedge clk)
  begin
    if (stall !== 1)
    begin
      pc_count <= pc_count + 4;
      if (reset)
      begin  
        pc_count <= 0;
      end
    end
  end

endmodule
