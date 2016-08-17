module arithmetic_logical_unit(stall, clk, inst, oprand1, oprand2, to_mem1, inst2, pre_target_enable, result, to_mem2, pc_count, target, target_enable, mod_inst, mod_pc, true_taken);
  
  input stall, clk, inst, oprand1, oprand2, to_mem1;
  
  output inst2, result, to_mem2;
  
  input wire [31:0] pc_count;
  input wire pre_target_enable;
  output reg [31:0] target, mod_inst, mod_pc;
  output reg target_enable, true_taken;

  wire[31:0] inst, oprand1, oprand2, to_mem1;
  
  reg[31:0] inst2, result, to_mem2;
  
  wire[5:0] op;
  
  assign op = inst[31:26];


  
  always @(posedge clk)   
  begin
    mod_inst = inst;
    mod_pc = pc_count;
    if (op == 6'b000010 | op == 6'b000101 | op == 6'b00010)
    begin
      true_taken = (op == 6'b000100 & oprand1 == oprand2) 
                    | (op == 6'b000101 & oprand1 != oprand2) 
                    | (op == 6'b000010);
      if (true_taken)
      begin
        target = (op == 6'b000010) ? {pc_count[31:28], inst[25:0], 2'b00} : {{14{inst[15]}}, inst[15:0], 2'b00} + pc_count + 4;
      end
      else
      begin
        target = pc_count + 4;
      end
      target_enable = true_taken != pre_target_enable;
    end
    else 
    begin
      target_enable <= 0;
    end
    if (!stall)
    begin
    inst2 <= inst;
    to_mem2 <= to_mem1;
    case(inst[31:26])
      6'b000000: //REG
      case(inst[5:0])
        6'b100000: result <= oprand1 + oprand2; //100001 add %d,%s,%t
//100001 addu $d,$s,$t  
//100010 sub $d,$s,$t
//100011 subu $d,$s,$t    
//011000 mult $s,$t
        6'b011001: result <= oprand1 * oprand2; //011001 multu.kai $d,$s,$t
//011001 multu $s,$t
//011010 div $s, $t
//011011 divu $s, $t
        6'b100110: result <= oprand1 ^ oprand2; //100110 xor $d,$s,$t
//010000 mfhi $d
//010010 mflo $d 
        6'b000000: result <= oprand1 << 0; //000000 sll $d,$t,shamt
      endcase
     
      6'b001000:   result <= oprand1 + oprand2; //001000 addi $t,$s,C
      
      //Calculate address for lw/sw
      6'b100011:   result <= oprand1 + oprand2; //100011 lw $t,C($s)
      6'b101011:   result <= oprand1 + oprand2; //101011 sw $t,C($s)

      6'b001111:   result <= oprand2 << 16; //001111 lui $t,C

//000100 beq $s,$t,C
//000101 bne $s,$t,C
//000010 j C

    endcase
    end
  end
  
endmodule
