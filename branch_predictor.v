module branch_predictor(predict_pc, predict_instruction, modify_instruction, modify_pc, true_taken, clk, predict_taken, branch_pc);

input wire [31:0] predict_pc, predict_instruction, modify_pc, modify_instruction;
input wire true_taken;
input wire clk;

output reg predict_taken;
output reg [31:0] branch_pc;

reg bhr_old, bhr_new; // global history table
reg [255:0] pht [3:0]; // pattern history table

parameter beq = 6'b000100;
parameter bne = 6'b000101;
parameter k = 8; //useless parameter, just to remind that it supports up to 2^8 = 128 instructions

integer index;
integer selection;
integer i;
reg [1:0] tmp;

initial 
begin
	/*some initialization*/

	for (i = 0; i < 4; i = i + 1) 
		pht[i] <= {128{2'b01}};
	bhr_old <= 0;
	bhr_new <= 0;
end

always @(predict_instruction or modify_instruction or modify_pc or true_taken)
begin
	//first, do the modification of bhr and pht
	if (modify_instruction[31:26] == bne || modify_instruction[31:26] == beq)
	begin
		index = modify_pc[9:2];
		selection = {bhr_old , bhr_new};

		case ({pht[selection][index * 2], pht[selection][index * 2 + 1]}) 
			2'b11:
			begin
				if (true_taken == 1) tmp = 2'b11;
				if (true_taken == 0) tmp = 2'b10;
			end

			2'b10:
			begin
				if (true_taken == 1) tmp = 2'b11;
				if (true_taken == 0) tmp = 2'b00;
			end

			2'b01:
			begin
				if (true_taken == 1) tmp = 2'b11;
				if (true_taken == 0) tmp = 2'b00;
			end

			2'b00:
			begin
				if (true_taken == 1) tmp = 2'b01;
				if (true_taken == 0) tmp = 2'b00;
			end

		endcase

		{pht[selection][index * 2], pht[selection][index * 2 + 1]} = tmp;
		bhr_old = bhr_new;
		bhr_new = true_taken;
	end

	//then, give the prediction
	if (predict_instruction[31:26] == beq || predict_instruction[31:26] == bne)
	begin	
		index = predict_pc[9:2];
		selection = {bhr_old , bhr_new};
		case ({pht[selection][index * 2], pht[selection][index * 2 + 1]})
			2'b11:
				predict_taken = 1;
			2'b10:
				predict_taken = 1;
			2'b01:
				predict_taken = 0;
			2'b00:
				predict_taken = 0;
		endcase
		branch_pc = {predict_pc[31:2] + {{14{predict_instruction[15]}}, predict_instruction[15:0]}, 2'b00} + 4;
	end
	else
	begin
	  predict_taken = 0;
	  branch_pc = 32'b0;
	end
end

endmodule