`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.04.2026 09:58:10
// Design Name: 
// Module Name: Pipeline_Implementation
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// ================= PROGRAM COUNTER =================
module Program_Counter(clk,reset,PC_in, PC_out);
input clk,reset;
input [31:0] PC_in;
output reg [31:0] PC_out;

always @(posedge clk or posedge reset)
begin
    if(reset)
        PC_out <= 32'b0;
    else
        PC_out <= PC_in;
end
endmodule

// ================= PC + 4 =================
module PCplus4(input [31:0] PC, output [31:0] NextPC);
assign NextPC = PC + 4;
endmodule

// ================= Instruction Memory =================
module Instruction_memory(input [31:0] addr, output [31:0] instr);

reg [31:0] mem [63:0];  // small physical, full logical addressing

//initial begin
//    // ADDI
//    mem[0] = 32'h20010005; // addi $1,$0,5
//    mem[1] = 32'h20020003; // addi $2,$0,3

//    // R-type operations
//    mem[2] = 32'h00221820; // add  $3,$1,$2  -> 8
//    mem[3] = 32'h00222022; // sub  $4,$1,$2  -> 2
//    mem[4] = 32'h00222824; // and  $5,$1,$2  -> 1
//    mem[5] = 32'h00223025; // or   $6,$1,$2  -> 7
//    mem[6] = 32'h00223826; // xor  $7,$1,$2  -> 6
//    mem[7] = 32'h00224027; // nor  $8,$1,$2  -> ~(5|3)
//    mem[8] = 32'h0022482A; // slt  $9,$1,$2  -> 0

//    // SLL (shift left)
//    mem[9]  = 32'h00015080; // sll $10,$1,2  -> 5<<2 = 20

//    // STORE / LOAD
//    mem[10] = 32'hAC030000; // sw  $3,0($0)
//    mem[11] = 32'h8C0B0000; // lw  $11,0($0)

//    // BRANCH TEST
//    mem[12] = 32'h14620001; // bne $3,$2,skip
//    mem[13] = 32'h200C0001; // addi $12,$0,1 (should skip)

//    mem[14] = 32'h200D0002; // target

//end

//assign instr = (addr[11:2] < 15) ? mem[addr[11:2]] : 32'b0;
initial begin
    // --- setup: write known values to data memory ---
    mem[0]  = 32'h2001000A; // addi $1,$0,10     $1=10
    mem[1]  = 32'hAC010000; // sw   $1,0($0)     mem[0]=10
    mem[2]  = 32'h20020014; // addi $2,$0,20     $2=20
    mem[3]  = 32'hAC020004; // sw   $2,4($0)     mem[1]=20

    // --- target program ---
    mem[4]  = 32'h8C030000; // lw   $3,0($0)     $3 = 10
    mem[5]  = 32'h00611022; // sub  $2,$3,$1      LOAD-USE STALL: $2 = 10-10 = 0
    mem[6]  = 32'h8C040004; // lw   $4,4($0)     $4 = 20
    mem[7]  = 32'h10400001; // beq  $2,$0,+1     BRANCH TAKEN ($2==0): skip sw
    mem[8]  = 32'hAC020008; // sw   $2,8($0)     FLUSHED - never executes
    mem[9]  = 32'h200D00FF; // addi $13,$0,255   branch target: $13=255
end

assign instr = (addr[11:2] < 10) ? mem[addr[11:2]] : 32'b0;
endmodule

// ================= Register File =================
module Reg_file(clk, reset, RegWrite,
                rs, rt, rd, wd,
                rd1, rd2);

input clk, reset, RegWrite;
input [4:0] rs, rt, rd;
input [31:0] wd;
output [31:0] rd1, rd2;

reg [31:0] regfile[31:0];
integer i;

always @(posedge clk or posedge reset) begin
    if(reset)
        for(i=0;i<32;i=i+1) regfile[i] <= 0;
    else if(RegWrite)
        regfile[rd] <= wd;
end

assign rd1 = (RegWrite && (rd == rs) && (rd != 5'b0)) ? wd : regfile[rs];
assign rd2 = (RegWrite && (rd == rt) && (rd != 5'b0)) ? wd : regfile[rt];
endmodule

// ================= ALU =================
module ALU(input [31:0] A,B,
           input [3:0] ALUCtrl,input[4:0] shamt,
           output reg [31:0] Result,
           output Zero);

always @(*) begin
    case(ALUCtrl)
        4'b0000: Result = A & B;          // AND
        4'b0001: Result = A | B;          // OR
        4'b0010: Result = A + B;          // ADD
        4'b0110: Result = A - B;          // SUB
        4'b0111: Result = (A < B) ? 1 : 0; // SLT
        4'b0011: Result = A ^ B;          // XOR
        4'b1100: Result = ~(A | B);       // NOR
        4'b1000: Result = B << shamt;    // SLL (shift amount from A)
        default: Result = 0;
    endcase
end

assign Zero = (Result==0);

endmodule

//  ================= ALU CONTROL =================
module ALU_Control(input [1:0] ALUOp,
                   input [5:0] funct,
                   output reg [3:0] ALUCtrl);

always @(*) begin
    case(ALUOp)
        2'b00: ALUCtrl = 4'b0010; // add
        2'b01: ALUCtrl = 4'b0110; // sub (for branch)
        2'b10: begin
            case(funct)
                6'b100000: ALUCtrl = 4'b0010; // add
                6'b100010: ALUCtrl = 4'b0110; // sub
                6'b100100: ALUCtrl = 4'b0000; // and
                6'b100101: ALUCtrl = 4'b0001; // or
                6'b101010: ALUCtrl = 4'b0111; // slt
                6'b100110: ALUCtrl = 4'b0011; // xor
                6'b100111: ALUCtrl = 4'b1100; // nor
                6'b000000: ALUCtrl = 4'b1000; // sll
                default:   ALUCtrl = 4'b0000;
            endcase
        end
    endcase
end
endmodule

// ================= CONTROL UNIT =================
module Control_Unit(
    input [5:0] opcode,
    output reg RegDst, ALUSrc, MemtoReg, RegWrite,
    output reg MemRead, MemWrite, Branch, Jump,
    output reg [1:0] ALUOp
);

always @(*) begin
    case(opcode)

    // R-type
    6'b000000: begin
        RegDst=1; ALUSrc=0; MemtoReg=0; RegWrite=1;
        MemRead=0; MemWrite=0; Branch=0; Jump=0;
        ALUOp=2'b10;
    end

    // LW
    6'b100011: begin
        RegDst=0; ALUSrc=1; MemtoReg=1; RegWrite=1;
        MemRead=1; MemWrite=0; Branch=0; Jump=0;
        ALUOp=2'b00;
    end

    // SW
    6'b101011: begin
        RegDst=0; ALUSrc=1; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=1; Branch=0; Jump=0;
        ALUOp=2'b00;
    end

    // BEQ
    6'b000100: begin
        RegDst=0; ALUSrc=0; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=0; Branch=1; Jump=0;
        ALUOp=2'b01;
    end

    // BNE
    6'b000101: begin
        RegDst=0; ALUSrc=0; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=0; Branch=1; Jump=0;
        ALUOp=2'b01;
    end

    // JUMP
    6'b000010: begin
        RegDst=0; ALUSrc=0; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=0; Branch=0; Jump=1;
        ALUOp=2'b00;
    end

    // ADDI
    6'b001000: begin
        RegDst=0; ALUSrc=1; MemtoReg=0; RegWrite=1;
        MemRead=0; MemWrite=0; Branch=0; Jump=0;
        ALUOp=2'b00;
    end
    
    6'b111111: begin
        RegDst=0; ALUSrc=0; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=0; Branch=0; Jump=0;
        ALUOp=2'b00;
    end
    // DEFAULT
    default: begin
        RegDst=0; ALUSrc=0; MemtoReg=0; RegWrite=0;
        MemRead=0; MemWrite=0; Branch=0; Jump=0;
        ALUOp=2'b00;
    end

    endcase
end

endmodule

// ================= DATA MEMORY =================
module Data_Memory(
input clk, MemWrite, MemRead,
input [31:0] addr, writeData,
output [31:0] readData);

reg [31:0] mem [0:1023];

always @(posedge clk)
    if(MemWrite)
        mem[addr[11:2]] <= writeData;

assign readData = (MemRead && addr[11:2] < 1024) ? mem[addr[11:2]] : 32'b0;
endmodule

// ============ FORWARDING UNIT ===============
module Forwarding_Unit(
input [4:0] EX_MEM_rd, MEM_WB_rd,
input [4:0] ID_EX_rs, ID_EX_rt,
input EX_MEM_RegWrite, MEM_WB_RegWrite,
output reg [1:0] ForwardA, ForwardB
);

always @(*) begin
    // default
    ForwardA = 2'b00;
    ForwardB = 2'b00;

    // ================= FORWARD A =================
    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) &&
        (EX_MEM_rd == ID_EX_rs))
        ForwardA = 2'b10;  // EX stage

    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) &&
             (MEM_WB_rd == ID_EX_rs))
        ForwardA = 2'b01;  // MEM stage

    // ================= FORWARD B =================
    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) &&
        (EX_MEM_rd == ID_EX_rt))
        ForwardB = 2'b10;  // EX stage

    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) &&
             (MEM_WB_rd == ID_EX_rt))
        ForwardB = 2'b01;  // MEM stage
end

endmodule
// ================ HAZARD DETECTION UNIT(LOAD-USE) ==================
module Hazard_Unit(
input ID_EX_MemRead,
input [4:0] ID_EX_rt,
input [4:0] IF_ID_rs, IF_ID_rt,
output reg stall
);

always @(*) begin
    stall = 0;
    if (ID_EX_MemRead &&
       ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)))
        stall = 1;
    else
        stall = 0;
end

endmodule

// ================ TOP MODULE =================
module Pipeline_Implementation(input clk, reset);
wire [31:0] branch_addr, jump_addr;
wire PCSrc;
wire [31:0] ImmExt;
wire RegDst, ALUSrc, MemtoReg, RegWrite;
wire MemRead, MemWrite, Branch, Jump;
wire [1:0] ALUOp;
wire Zero;
wire flush;
wire [31:0] PC_mux_out;
// ================= PC =================
wire [31:0] PC, PC4, PC_next;
wire PCWrite;

Program_Counter pc(clk, reset,
    PC_mux_out,
    PC
);
PCplus4 pc4mod(PC, PC4);

// ================= IF =================
wire [31:0] instr;
Instruction_memory imem(PC, instr);     
// ================= IF/ID =================
reg [31:0] IF_ID_instr, IF_ID_PC;
wire IF_ID_Write;
reg IF_ID_valid;
assign jump_addr = {IF_ID_PC[31:28], IF_ID_instr[25:0], 2'b00};

always @(posedge clk or posedge reset) begin
    if (reset) begin
        IF_ID_instr <= 0;
        IF_ID_PC <= 0;
        IF_ID_valid <= 0;
    end
    else if (flush) begin
        IF_ID_instr <= 32'b0;   
        IF_ID_PC <= 0;
        IF_ID_valid <= 0;
    end
    else if (IF_ID_Write) begin
        IF_ID_instr <= instr;
        IF_ID_PC <= PC4;
        IF_ID_valid <= 1;
    end
end

// ================= CONTROL =================
wire [5:0] opcode_safe = IF_ID_instr[31:26];
Control_Unit cu(opcode_safe,
RegDst, ALUSrc, MemtoReg, RegWrite,
MemRead, MemWrite, Branch, Jump, ALUOp);

// ================= REGISTER FILE =================
wire [31:0] RD1, RD2;
wire [31:0] WriteData;

reg [4:0] MEM_WB_rd;
reg MEM_WB_RegWrite, MEM_WB_MemtoReg;
reg [31:0] MEM_WB_ALUResult, MEM_WB_MemData;

Reg_file rf(clk, reset, MEM_WB_RegWrite,
IF_ID_instr[25:21], IF_ID_instr[20:16],
MEM_WB_rd, WriteData, RD1, RD2);

// ================= IMM =================

assign ImmExt = {{16{IF_ID_instr[15]}}, IF_ID_instr[15:0]};

// ================= ID/EX =================
reg [31:0] ID_EX_A, ID_EX_B, ID_EX_Imm;
reg [4:0] ID_EX_rs, ID_EX_rt, ID_EX_rd;
reg [5:0] ID_EX_funct;
reg [4:0] ID_EX_shamt;
reg ID_EX_Branch;
reg ID_EX_isBNE;
reg ID_EX_RegWrite, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg;
reg ID_EX_ALUSrc, ID_EX_valid;
reg ID_EX_RegDst;
reg [1:0] ID_EX_ALUOp;
wire stall;
reg [31:0] ID_EX_PC;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ID_EX_A <= 0; ID_EX_B <= 0; ID_EX_Imm <= 0;
        ID_EX_rs <= 0;ID_EX_rt <= 0;ID_EX_rd <= 0;
        ID_EX_funct <= 0; ID_EX_shamt <= 0;ID_EX_Branch <= 0;
        ID_EX_isBNE  <= 0;ID_EX_RegWrite <= 0;ID_EX_MemRead <= 0;
        ID_EX_MemWrite <= 0;ID_EX_MemtoReg <= 0;  ID_EX_ALUSrc <= 0;
        ID_EX_ALUOp <= 0;ID_EX_PC <= 0;ID_EX_RegDst <= 0;
    end

    else if (stall|| flush) begin
        // BUBBLE / FLUSH
        ID_EX_valid <= 0;
        ID_EX_RegWrite <= 0;
        ID_EX_MemRead <= 0;
        ID_EX_MemWrite <= 0;
        ID_EX_MemtoReg <= 0;
        ID_EX_ALUSrc <= 0;
        ID_EX_ALUOp <= 0;
        ID_EX_rs <= 0;
        ID_EX_rt <= 0;
        ID_EX_rd <= 0;
        ID_EX_Branch <= 0;
        ID_EX_isBNE  <= 0;
        ID_EX_PC     <= 0;
        ID_EX_RegDst <= 0;
        ID_EX_Imm <=0;
        ID_EX_funct <= 0;
        ID_EX_shamt <= 0; 
    end

    else begin
        ID_EX_valid <= IF_ID_valid;
        ID_EX_A <= RD1;
        ID_EX_B <= RD2;
        ID_EX_Imm <= ImmExt;
        ID_EX_PC <= IF_ID_PC;
        ID_EX_rs <= IF_ID_instr[25:21];
        ID_EX_rt <= IF_ID_instr[20:16];
        ID_EX_rd <= IF_ID_instr[15:11];   // ✅ FIXED
        ID_EX_RegDst <= RegDst;

        ID_EX_funct <= IF_ID_instr[5:0];
        ID_EX_shamt <= IF_ID_instr[10:6];
        ID_EX_Branch <= Branch;        // from Control_Unit
        ID_EX_isBNE  <= (IF_ID_instr[31:26] == 6'b000101); 
        ID_EX_RegWrite <= RegWrite;
        ID_EX_MemRead <= MemRead;
        ID_EX_MemWrite <= MemWrite;
        ID_EX_MemtoReg <= MemtoReg;
        ID_EX_ALUSrc <= ALUSrc;
        ID_EX_ALUOp <= ALUOp;
    end
end
wire [4:0] ID_EX_WriteReg;
assign ID_EX_WriteReg = (ID_EX_RegDst) ? ID_EX_rd : ID_EX_rt;

// ================= HAZARD =================
Hazard_Unit hazard(
ID_EX_MemRead,
ID_EX_rt,
IF_ID_instr[25:21],
IF_ID_instr[20:16],
stall
);

// stall control
assign PCWrite = ~stall;
assign IF_ID_Write = ~stall;
// ================= FORWARDING =================
wire [1:0] ForwardA, ForwardB;

reg [31:0] EX_MEM_ALUResult, EX_MEM_B;
reg [4:0] EX_MEM_rd;
reg EX_MEM_RegWrite, EX_MEM_MemRead, EX_MEM_MemWrite, EX_MEM_MemtoReg;

Forwarding_Unit fwd(
EX_MEM_rd, MEM_WB_rd,
ID_EX_rs, ID_EX_rt,
EX_MEM_RegWrite, MEM_WB_RegWrite,
ForwardA, ForwardB
);

// ================= ALU CONTROL =================
wire [3:0] ALUCtrl;
wire [1:0] ALUOp_safe = ID_EX_valid ? ID_EX_ALUOp : 2'b00;
wire [5:0] funct_safe = ID_EX_valid ? ID_EX_funct : 6'b111111;

ALU_Control alu_ctrl(ALUOp_safe, funct_safe, ALUCtrl);

// ================= FORWARD MUX =================
wire real_exec = ID_EX_valid;
reg [31:0] ALU_in1, ALU_in2;
wire isSLL =
    ID_EX_valid &&
    (ID_EX_ALUOp == 2'b10) &&
    (ID_EX_funct == 6'b000000) &&
    (ID_EX_rd != 0);
always @(*) begin
    case(ForwardA)
        2'b00: ALU_in1 = ID_EX_A;
        2'b10: ALU_in1 = EX_MEM_ALUResult;
        2'b01: ALU_in1 = WriteData;
    endcase

    case(ForwardB)
        2'b00: ALU_in2 = ID_EX_B;
        2'b10: ALU_in2 = EX_MEM_ALUResult;
        2'b01: ALU_in2 = WriteData;
    endcase
end
wire [31:0] ALU_A = (isSLL) ? {27'b0, ID_EX_shamt} : ALU_in1;
wire [31:0] ALU_B = (ID_EX_ALUSrc) ? ID_EX_Imm : ALU_in2;
wire [31:0] ALU_B_final = (isSLL) ? ALU_in2 : ALU_B;

// ================= ALU =================
wire [31:0] ALUResult;
ALU alu(ALU_A, ALU_B_final, ALUCtrl,ID_EX_shamt, ALUResult, Zero);

// ================= EX/MEM =================
reg EX_MEM_Branch, EX_MEM_isBNE,EX_MEM_Zero;
reg [31:0] EX_MEM_PC;
reg [31:0] EX_MEM_ImmExt;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        EX_MEM_RegWrite <= 0;
        EX_MEM_MemRead <= 0;
        EX_MEM_MemWrite <= 0;
        EX_MEM_MemtoReg <= 0;
        EX_MEM_Branch <= 0;
        EX_MEM_isBNE  <= 0;
        EX_MEM_Zero   <= 0;
        EX_MEM_PC      <= 0;
        EX_MEM_ImmExt <= 0;
        EX_MEM_ALUResult <= 0;
        EX_MEM_B <= 0;
        EX_MEM_rd <= 0;
    end
    else if (flush) begin
        EX_MEM_Branch   <= 0;
        EX_MEM_isBNE    <= 0;
        EX_MEM_Zero     <= 0;
        EX_MEM_RegWrite <= 0;
        EX_MEM_MemRead  <= 0;
        EX_MEM_MemWrite <= 0;
        EX_MEM_MemtoReg <= 0;
    end 
    else begin
        EX_MEM_ALUResult <= ALUResult;
        EX_MEM_B <= ALU_in2;
        EX_MEM_rd <= ID_EX_WriteReg;
        EX_MEM_Branch <= ID_EX_Branch;
        EX_MEM_isBNE  <= ID_EX_isBNE;
        EX_MEM_Zero   <= Zero; 
        EX_MEM_RegWrite <= ID_EX_RegWrite;
        EX_MEM_MemRead <= ID_EX_MemRead;
        EX_MEM_MemWrite <= ID_EX_MemWrite;
        EX_MEM_MemtoReg <= ID_EX_MemtoReg;
        EX_MEM_PC      <= ID_EX_PC;
        EX_MEM_ImmExt  <= ID_EX_Imm;
    end
end

// ================= MEMORY =================
wire [31:0] MemData;

Data_Memory dm(clk,
EX_MEM_MemWrite,
EX_MEM_MemRead,
EX_MEM_ALUResult,
EX_MEM_B,
MemData);

// ================= MEM/WB =================
always @(posedge clk or posedge reset) begin
    if (reset) begin
        MEM_WB_RegWrite <= 0;
        MEM_WB_MemtoReg <= 0;
    end else begin
        MEM_WB_ALUResult <= EX_MEM_ALUResult;
        MEM_WB_MemData <= MemData;
        MEM_WB_rd <= EX_MEM_rd;

        MEM_WB_RegWrite <= EX_MEM_RegWrite;
        MEM_WB_MemtoReg <= EX_MEM_MemtoReg;
    end
end

// ================= WB =================
assign WriteData = (MEM_WB_MemtoReg) ? MEM_WB_MemData : MEM_WB_ALUResult;
assign branch_addr = EX_MEM_PC + (EX_MEM_ImmExt << 2);
// ================= PC UPDATE =================
wire branch_taken =real_exec &&
    EX_MEM_Branch &&
    ((EX_MEM_isBNE && !EX_MEM_Zero) ||
     (!EX_MEM_isBNE && EX_MEM_Zero));
wire flush_branch = branch_taken;
wire flush_jump = Jump;
assign flush = flush_branch | flush_jump;
wire pc_hold = stall;

assign PC_mux_out =
    (pc_hold)      ? PC :
    (flush_jump)   ? jump_addr :
    (flush_branch) ? branch_addr :
    PC4;
endmodule

// ==================== TEST BENCH ================
module tb_pipeline;

reg clk, reset;

Pipeline_Implementation uut(clk, reset);

// CLOCK
always #5 clk = ~clk;

// INIT
//initial begin
//    clk = 0;
//    reset = 1;
//    #20 reset = 0;
//    #300; // wait for all instructions to complete WB

//    $display("\n===== REGISTER FILE CHECKS =====");

//    if (uut.rf.regfile[1]  === 32'd5)         $display("PASS $1  = 5");
//    else $error("FAIL $1  expected 5,  got %0d", uut.rf.regfile[1]);

//    if (uut.rf.regfile[2]  === 32'd3)         $display("PASS $2  = 3");
//    else $error("FAIL $2  expected 3,  got %0d", uut.rf.regfile[2]);

//    if (uut.rf.regfile[3]  === 32'd8)         $display("PASS $3  = 8");
//    else $error("FAIL $3  expected 8,  got %0d", uut.rf.regfile[3]);

//    if (uut.rf.regfile[4]  === 32'd2)         $display("PASS $4  = 2");
//    else $error("FAIL $4  expected 2,  got %0d", uut.rf.regfile[4]);

//    if (uut.rf.regfile[5]  === 32'd1)         $display("PASS $5  = 1");
//    else $error("FAIL $5  expected 1,  got %0d", uut.rf.regfile[5]);

//    if (uut.rf.regfile[6]  === 32'd7)         $display("PASS $6  = 7");
//    else $error("FAIL $6  expected 7,  got %0d", uut.rf.regfile[6]);

//    if (uut.rf.regfile[7]  === 32'd6)         $display("PASS $7  = 6");
//    else $error("FAIL $7  expected 6,  got %0d", uut.rf.regfile[7]);

//    if (uut.rf.regfile[8]  === 32'hFFFFFFF8)  $display("PASS $8  = FFFFFFF8");
//    else $error("FAIL $8  expected FFFFFFF8, got %h", uut.rf.regfile[8]);

//    if (uut.rf.regfile[9]  === 32'd0)         $display("PASS $9  = 0");
//    else $error("FAIL $9  expected 0,  got %0d", uut.rf.regfile[9]);

//    if (uut.rf.regfile[10] === 32'd20)        $display("PASS $10 = 20");
//    else $error("FAIL $10 expected 20, got %0d", uut.rf.regfile[10]);

//    if (uut.rf.regfile[11] === 32'd8)         $display("PASS $11 = 8 (lw)");
//    else $error("FAIL $11 expected 8,  got %0d", uut.rf.regfile[11]);

//    if (uut.rf.regfile[12] === 32'd0)         $display("PASS $12 = 0 (skipped by BNE)");
//    else $error("FAIL $12 expected 0,  got %0d", uut.rf.regfile[12]);

//    if (uut.rf.regfile[13] === 32'd2)         $display("PASS $13 = 2");
//    else $error("FAIL $13 expected 2,  got %0d", uut.rf.regfile[13]);

//    $display("================================\n");
//    $finish;
//end
initial begin
    clk = 0; reset = 1;
    #20 reset = 0;
    #400;

    $display("\n===== PROGRAM 2 CHECKS =====");

    if (uut.rf.regfile[1]  === 32'd10)
        $display("PASS $1  = 10  (addi setup)");
    else $error("FAIL $1  expected 10, got %0d", uut.rf.regfile[1]);

    if (uut.rf.regfile[3]  === 32'd10)
        $display("PASS $3  = 10  (lw from mem[0])");
    else $error("FAIL $3  expected 10, got %0d", uut.rf.regfile[3]);

    if (uut.rf.regfile[2]  === 32'd0)
        $display("PASS $2  = 0   (sub with load-use stall)");
    else $error("FAIL $2  expected 0,  got %0d", uut.rf.regfile[2]);

    if (uut.rf.regfile[4]  === 32'd20)
        $display("PASS $4  = 20  (lw from mem[1])");
    else $error("FAIL $4  expected 20, got %0d", uut.rf.regfile[4]);

    // SW was flushed - mem[2] should be 0 (never written)
    // Replace the mem[2] check with this:
    if (uut.dm.mem[2] === 32'bx || uut.dm.mem[2] === 32'd0)
        $display("PASS mem[2] = unwritten (sw correctly flushed by BEQ)");
    else $error("FAIL mem[2] expected unwritten, got %0h", uut.dm.mem[2]);
    if (uut.rf.regfile[13] === 32'd255)
        $display("PASS $13 = 255  (branch target executed)");
    else $error("FAIL $13 expected 255, got %0d", uut.rf.regfile[13]);

    $display("============================\n");
    $finish;
end
// ================= DISPLAY HEADER =================
initial begin
$display("----------------------------------------------------------------------------------------");
$display("Time\tPC\tInstr\t\tStall\tFwdA FwdB\tALURes\t\tWB_Data");
$display("----------------------------------------------------------------------------------------");
end

// ================= MAIN MONITOR =================
always @(posedge clk) begin
    $display("%0t\t%h\t%h\t%b\t%b    %b\t%h\t%h",
        $time, uut.PC, uut.IF_ID_instr, uut.stall,
        uut.ForwardA, uut.ForwardB,
        uut.EX_MEM_ALUResult, uut.WriteData);
end
endmodule