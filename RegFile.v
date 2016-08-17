module RegFile(instruction_in, WBInstruction, DataOut, clk, A, B, wdata, instruction_out);

input wire [31:0] instruction_in;
input wire [31:0] WBInstruction;
input wire [31:0] DataOut;
input clk;
output reg [31:0] A;
output reg [31:0] B;
output reg [31:0] wdata;
output reg [31:0] instruction_out;

reg RegWrite;
reg [4:0] ws;

reg [31:0] regFile[31:0];
wire [5:0] op;
wire [5:0] WBop, func;
integer immOrNot;

integer i;

parameter add   = 6'b100000;
parameter addi  = 6'b001000;
parameter addu  = 6'b100001;
parameter sub   = 6'b100010;
parameter subu  = 6'b100011;
parameter mult  = 6'b011000;
parameter multu = 6'b011001;
parameter div   = 6'b011010;
parameter divu  = 6'b011011;
parameter xxor  = 6'b100110;
parameter mfhi  = 6'b010000;
parameter mflo  = 6'b010010;
parameter sll   = 6'b000000;
parameter lw    = 6'b100011;
parameter sw    = 6'b101011;
parameter lui   = 6'b001111;
parameter beq   = 6'b000100;
parameter bne   = 6'b000101;
parameter j     = 6'b000010;


assign op = instruction_in[31:26];
assign WBop = WBInstruction[31:26];
assign func = WBInstruction[5:0];

initial begin
	for (i = 0; i < 32; i = i + 1)
		begin
			regFile[i] = 0;
		end
end

always @(posedge clk)
begin   
    instruction_out = instruction_in;


    //-------------------------------WB------------------------------
    case (WBop) 
        6'b000000:
            case (func)         
                /*alu operations*/
                add, addu, sub, subu, xxor: 
                    begin
                        RegWrite = 1;
                        ws = WBInstruction[15:11];
                    end
            endcase
        /*load instructions*/
        lw, lui, addi:
            begin
                RegWrite = 1;
                ws = WBInstruction[20:16];
            end
        /*other operations, no need to write back*/
        default:
            RegWrite = 0;
    endcase

    if (RegWrite == 1) 
        begin
            regFile[ws] = DataOut;
        end
        
    /*TODO: mfhi and mflo are not supported yet*/
//-------------------------read---------------------------------    
    case (op)
    /*I-type instructions*/
        addi, lui, lw, sw:
           immOrNot = 1;
    /*R-type instructions*/    
       default:
           immOrNot = 0;
    endcase

    if (immOrNot == 0) 
        begin
            A = regFile[instruction_in[25:21]];
            B = regFile[instruction_in[20:16]];            
        end
    else 
        begin
            A = regFile[instruction_in[25:21]];
            B = {{16{instruction_in[15]}}, instruction_in[15:0]};
        end
    wdata = regFile[instruction_in[20:16]];



end

endmodule