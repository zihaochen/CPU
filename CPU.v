`timescale 10ns/10ns

module CPU;
  
  reg clk, reset;
  
  wire[31:0] pc_count, pc_count2, pc_count3, 
             inst_IF, inst_ID, inst_EX, inst_MEM, 
             oprand1, oprand2, result, 
             to_mem_ID, to_mem_EX, wback, target; 
  wire[31:0] A, B, wdata, wdata_EX;
  wire target_enable;

  wire[31:0] pre_target, mod_inst, mod_pc;
  wire pre_target_enable, pre_target_enable1, true_taken;

  parameter lw     = 6'b100011;
  parameter sw     = 6'b101011;
  parameter ALU_op = 6'b000000;
  parameter addi  = 6'b001000;
  parameter nop    = 32'b0;
  parameter beq   = 6'b000100;
  parameter bne   = 6'b000101;

  wire stall, inst_stall, data_stall;

//---------------------bypassing begin---------------------------

  reg bypassingSwitch;

  wire Ex_to_ExA,     Ex_to_ExB,     Mem_to_ExA,     Mem_to_ExB;
  wire Imm_Ex_to_ExA, Imm_Ex_to_ExB, Imm_Mem_to_ExA, Imm_Mem_to_ExB;
  wire Ld_Mem_to_ExA, Ld_Mem_to_ExB;
  wire Sw_Mem_to_Mem;

  assign Ex_to_ExA =  (inst_EX[31:26] == ALU_op) & 
                  //    (inst_ID[25:21] != 0) &
                      (inst_EX[15:11] == inst_ID[25:21]);
  assign Ex_to_ExB =  (inst_EX[31:26] == ALU_op) &
                      (inst_ID[31:26] == ALU_op | inst_ID[31:26] == bne | inst_ID[31:26] == beq) &
                    //  (inst_ID[25:21] != 0) &
                      (inst_EX[15:11] == inst_ID[20:16]);

  assign Mem_to_ExA = (inst_MEM[31:26] == ALU_op) & 
                    //  (inst_ID[25:21] != 0) &
                      (inst_MEM[15:11] == inst_ID[25:21]);
  assign Mem_to_ExB = (inst_MEM[31:26] == ALU_op) &
                      (inst_ID[31:26] == ALU_op | inst_ID[31:26] == bne | inst_ID[31:26] == beq) &

                    //  (inst_ID[25:21] != 0) &
                      (inst_MEM[15:11] == inst_ID[20:16]);

  assign Imm_Ex_to_ExA =  (inst_EX[31:26] == addi) &
                      //    (inst_ID[25:21] != 0) &
                          (inst_EX[20:16] == inst_ID[25:21]);
  assign Imm_Ex_to_ExB =  (inst_EX[31:26] == addi) &
                          (inst_ID[31:26] == ALU_op | inst_ID[31:26] == bne | inst_ID[31:26] == beq) &
                       //   (inst_ID[25:21] != 0) &
                          (inst_EX[20:16] == inst_ID[20:16]);

  assign Imm_Mem_to_ExA = (inst_MEM[31:26] == addi) &
                        //  (inst_ID[25:21] != 0) &
                          (inst_MEM[20:16] == inst_ID[25:21]);
  assign Imm_Mem_to_ExB = (inst_MEM[31:26] == addi) &
                          (inst_ID[31:26] == ALU_op | inst_ID[31:26] == bne | inst_ID[31:26] == beq) &
                        //  (inst_ID[25:21] != 0) &
                          (inst_MEM[20:16] == inst_ID[20:16]);

  assign Ld_Mem_to_ExA =  (inst_MEM[31:26] == lw) &
                        //  (inst_ID[25:21] != 0) &
                          (inst_MEM[20:16] == inst_ID[25:21]);
  assign Ld_Mem_to_ExB =  (inst_MEM[31:26] == lw) &
                          (inst_ID[31:26] == ALU_op | inst_ID[31:26] == bne | inst_ID[31:26] == beq ) &
                        //  (inst_ID[25:21] != 0) &
                          (inst_MEM[20:16] == inst_ID[20:16]);

  assign Sw_Mem_to_Mem =  (inst_EX[31:26] == sw) &
                          (((inst_MEM[15:11] == inst_EX[20:16]) & (inst_MEM[31:26] == ALU_op)) |
                          ((inst_MEM[20:16] == inst_EX[20:16]) & (inst_MEM[31:26] == lw)));

  assign Sw_Mem_to_Ex = (inst_ID[31:26] == sw) &
                        ((inst_MEM[31:26] == ALU_op & inst_ID[20:16] == inst_MEM[15:11]) |
                        (inst_MEM[31:26] == lw & inst_ID[20:16] == inst_MEM[20:16]));

  assign A =  (bypassingSwitch == 0) ? oprand1 :
              (Ex_to_ExA === 1  | Imm_Ex_to_ExA === 1) ? result :
              (Mem_to_ExA === 1 | Imm_Mem_to_ExA === 1| Ld_Mem_to_ExA === 1) ? wback :
              oprand1;
  assign B = (bypassingSwitch == 0) ? oprand2 :
              (Ex_to_ExB === 1 | Imm_Ex_to_ExB === 1) ? result :
              (Mem_to_ExB === 1 | Imm_Mem_to_ExB === 1 | Ld_Mem_to_ExB === 1) ? wback :
              oprand2;
  assign wdata =  (bypassingSwitch == 0) ? to_mem_EX :
                      (Sw_Mem_to_Mem === 1) ? wback :
                      to_mem_EX;

  assign wdata_EX = (bypassingSwitch == 0) ? to_mem_ID:
                      (Sw_Mem_to_Ex === 1) ? wback:
                      to_mem_ID;            


//---------------------bypassing end------------------------------


//---------------------stall begin--------------------------------- 
 // /*
  assign stall =  (inst_ID[31:26] == lw) &&
                  ((inst_IF[31:26] == ALU_op && inst_ID[20:16] == inst_IF[25:21]) |
                  (inst_IF[31:26] == ALU_op && inst_ID[20:16] == inst_IF[20:16]) |
                  (inst_IF[31:26] !=  ALU_op && inst_ID[20:16] == inst_IF[25:21]));             
//*/
 // assign stall = 0;
//---------------------stall end------------------------------------
  

  program_counter PC(stall | inst_stall | data_stall, clk, target, target_enable, pre_target, pre_target_enable, reset, pc_count);

  inst_memory IMEM(stall, data_stall, clk, reset, pc_count, target_enable, mod_inst, mod_pc, true_taken, inst_IF, inst_stall, pc_count2, pre_target_enable, pre_target);

  RegFile REG(stall ? nop : inst_IF, data_stall, pc_count2, inst_MEM, wback, clk, target_enable, pre_target_enable, oprand1, oprand2, to_mem_ID, inst_ID, pc_count3, pre_target_enable1);

  arithmetic_logical_unit ALU (data_stall, clk, inst_ID, A, B, wdata_EX, inst_EX, pre_target_enable1, result, to_mem_EX, pc_count3, target, target_enable, mod_inst, mod_pc, true_taken);

  data_memory DMEM(clk, result, inst_EX, wdata, data_stall, inst_MEM, wback);
  
  initial
  begin
    clk <= 0;
    bypassingSwitch <= 1;
    forever #1 clk = !clk;
  end

  initial
  begin
    reset <= 1;
    #1 reset <= 0;
  end
  
endmodule