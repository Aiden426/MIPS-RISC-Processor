`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2026 22:29:09
// Design Name: 
// Module Name: Multi_Cycle_Implementation
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
    if(reset) PC_out <= 0;
    else PC_out <= PC_in;
end
endmodule

// ================= MEMORY =================
module Memory(clk, MemRead, MemWrite, address, Write_data, Read_data);
input clk, MemRead, MemWrite;
input [31:0] address, Write_data;
output [31:0] Read_data;

reg [31:0] mem[63:0];

// PROGRAM
integer i;
initial begin
    for(i=0;i<64;i=i+1)begin
        mem[i] = 32'b0;   // or NOP
        end        
    // addi $t1, $zero, 5
    mem[0] = 32'b001000_00000_01001_0000000000000101;

    // addi $t2, $zero, 10
    mem[1] = 32'b001000_00000_01010_0000000000001010;

    // add $t3, $t1, $t2
    mem[2] = 32'b000000_01001_01010_01011_00000_100000;

    // sw $t3, 0($zero)
    mem[3] = 32'b101011_00000_01011_0000000000000000;

    // lw $t4, 0($zero)
    mem[4] = 32'b100011_00000_01100_0000000000000000;

    // beq $t4, $t3, +1
    mem[5] = 32'b000100_01100_01011_0000000000000001;

    // addi $t5, $zero, 99 (should skip)
    mem[6] = 32'b001000_00000_01101_0000000001100011;

    // addi $t6, $zero, 42
    mem[7] = 32'b001000_00000_01110_0000000000101010;
    
        // xor $t7, $t1, $t2  → expect 15
    mem[8] = 32'b000000_01001_01010_01111_00000_100110;
    
    // nor $s0, $t1, $t2
    mem[9] = 32'b000000_01001_01010_10000_00000_100111;
    
    // slt $s1, $t1, $t2 → expect 1
    mem[10] = 32'b000000_01001_01010_10001_00000_101010;
    
    // sll $s2, $t1, 2 → expect 20
    mem[11] = 32'b000000_00000_01001_10010_00010_000000;
    
    // bne $t1, $t2, +1 → should branch
    mem[12] = 32'b000101_01001_01010_0000000000000001;
end

// ASYNCHRONOUS READ
//assign Read_data = (MemRead) ? mem[address[7:2]] : 32'b0;
assign Read_data = mem[address[7:2]];

// SYNCHRONOUS WRITE
always @(posedge clk)
begin
    if(MemWrite)
        mem[address[7:2]] <= Write_data;
end

endmodule

// ================= REGISTER FILE =================
module Reg_file(clk,RegWrite, Rs, Rt, Rd, Write_data, read_data1, read_data2);
input clk,RegWrite;
input [4:0] Rs, Rt, Rd;
input [31:0] Write_data;
output [31:0] read_data1, read_data2;

reg [31:0] regf[31:0];
integer i;

initial begin
    for(i=0;i<32;i=i+1)
        regf[i] = 0;
end

assign read_data1 = regf[Rs];
assign read_data2 = regf[Rt];

always @(posedge clk)
begin
    if(RegWrite && Rd != 0)
        regf[Rd] <= Write_data;
end

endmodule

// ================= ALU =================
module ALU(A,B,ALUControl,Result,Zero);
input [31:0] A,B;
input [3:0] ALUControl;
output reg [31:0] Result;
output Zero;

always @(*)
begin
    case(ALUControl)
        4'b0000: Result = A & B;
        4'b0001: Result = A | B;
        4'b0010: Result = A + B;
        4'b0110: Result = A - B;
        4'b0111: Result = (A < B);
        4'b0011: Result = A ^ B;        // XOR
        4'b1100: Result = ~(A | B);     // NOR
        4'b1000: Result = B << A[4:0];       // SLL (A = shamt)

        default: Result = 0;
    endcase
end

assign Zero = (Result == 0);
endmodule

// ================= IMMEDIATE =================
module ImmGen(instruction, ImmExt);
input [31:0] instruction;
output [31:0] ImmExt;

assign ImmExt = {{16{instruction[15]}}, instruction[15:0]};
endmodule

// ================= SHIFT LEFT 2 =================
module ShiftLeft2(in, out);
input [31:0] in;
output [31:0] out;

assign out = in << 2;
endmodule

// ================= ALU CONTROL =================
module ALU_Control(ALUOp, funct, ALUCtrl);
input [1:0] ALUOp;
input [5:0] funct;
output reg [3:0] ALUCtrl;

always @(*) begin
    case(ALUOp)
        2'b00: ALUCtrl = 4'b0010; // add (lw, sw, addi)
        2'b01: ALUCtrl = 4'b0110; // sub (beq)
        2'b10: begin
            case(funct)
                6'b100000: ALUCtrl = 4'b0010; // add
                6'b100010: ALUCtrl = 4'b0110; // sub
                6'b100100: ALUCtrl = 4'b0000; // and
                6'b100101: ALUCtrl = 4'b0001; // or
                6'b100110: ALUCtrl = 4'b0011; // xor
                6'b100111: ALUCtrl = 4'b1100; // nor
                6'b101010: ALUCtrl = 4'b0111; // slt (already mapped)
                6'b000000: ALUCtrl = 4'b1000; // sll
                default:   ALUCtrl = 4'b0010;
            endcase
        end
        default: ALUCtrl = 4'b0010;
    endcase
end
endmodule

// ================= REG32 =================
module Reg32(clk, reset, enable, d, q);
input clk, reset, enable;
input [31:0] d;
output reg [31:0] q;

always @(posedge clk or posedge reset)
begin
    if(reset) q <= 0;
    else if(enable) q <= d;
end
endmodule

// ================= CONTROL FSM =================
module Control_Unit(
input clk, reset,
input [5:0] opcode,

output reg PCWrite, PCWriteCond,
output reg IorD, MemRead, MemWrite, IRWrite,
output reg RegDst, MemtoReg, RegWrite,
output reg ALUSrcA,BranchNE,
output reg [1:0] ALUSrcB,
output reg [1:0] PCSource,
output reg [1:0] ALUOp,
output [3:0] state_out
);

reg [3:0] state;
assign state_out = state;

parameter IF=0, ID=1, EX_R=2, EX_MEM=3, MEM_RD=4, MEM_WR=5, WB_LW=6, WB_R=7, BR=8, JUMP = 9;

always @(posedge clk or posedge reset)
begin
    if(reset) state <= IF;
    else
    case(state)
        IF: state <= ID;
        ID:
        case(opcode)
            6'b000000: state <= EX_R;   // R-type
            6'b000010: state <= JUMP;   // j instruction
            6'b001000: state <= EX_MEM;   // addi ✅
            6'b100011: state <= EX_MEM; // lw
            6'b101011: state <= EX_MEM; // sw
            6'b000100: state <= BR;     // beq
            6'b000101: state <= BR;   // ✅ BNE
            default:   state <= IF;
        endcase
        EX_R: state <= WB_R;
        EX_MEM:
            if(opcode==6'b100011) state <= MEM_RD;
            else if(opcode==6'b101011) state <= MEM_WR;
            else state <= WB_R;
        MEM_RD: state <= WB_LW;
        MEM_WR: state <= IF;
        WB_LW: state <= IF;
        WB_R: state <= IF;
        BR: state <= IF;
        JUMP: state <= IF;
    endcase
end

always @(*)
begin
    PCWrite=0; PCWriteCond=0; IorD=0; MemRead=0; MemWrite=0; IRWrite=0;
    RegDst=0; MemtoReg=0; RegWrite=0;
    ALUSrcA=0; ALUSrcB=0; PCSource=0; ALUOp=0;BranchNE=0;

    case(state)
    IF: begin
        MemRead = 1; IRWrite = 1;
        ALUSrcA = 0; ALUSrcB = 2'b01;   // +4
        PCWrite = 1; PCSource = 2'b00;
    end
    ID: begin
        ALUSrcA = 0;         // PC
        ALUSrcB = 2'b11;     // imm << 2
        ALUOp   = 2'b00;     // ADD
    end
    EX_R: begin
        ALUSrcA=1; ALUOp=2'b10;
    end
    EX_MEM: begin
        ALUSrcA=1; ALUSrcB=2'b10;
    end
    MEM_RD: begin
        MemRead=1; IorD=1;
    end
    MEM_WR: begin
        MemWrite=1; IorD=1;
    end
    WB_LW: begin
        RegWrite=1; MemtoReg=1;
    end
    WB_R: begin
        RegWrite=1; RegDst = (opcode == 6'b000000);
    end
    BR: begin
        ALUSrcA = 1;
        ALUSrcB = 2'b00;
        ALUOp = 2'b01; // SUB
        PCSource = 2'b01;
        PCWriteCond = 1;
        if(opcode == 6'b000100) begin
            BranchNE =0;   // BEQ
        end
        else if(opcode == 6'b000101) begin
            BranchNE = 1;      // BNE
        end
    end
    JUMP: begin
        PCWrite = 1;
        PCSource = 2'b10;
    end
    endcase
end
endmodule

// ================= TOP =================
module Multi_Cycle_Implementation(input clk,reset);

wire [31:0] PC, IR, MDR, ALUOut;
wire [31:0] A, B, A_reg, B_reg;
wire [31:0] ALUResult, ImmExt, ImmShift;
wire [31:0] WriteData;
wire Zero;

// control
wire PCWrite, PCWriteCond, IorD, MemRead, MemWrite, IRWrite;
wire RegDst, MemtoReg, RegWrite;
wire ALUSrcA;
wire [1:0] ALUSrcB, PCSource, ALUOp;
wire [3:0] ALUCtrl;
wire [31:0] PC_next;
wire [31:0] JumpAddr;
wire [3:0] state;
wire ABWrite = (state == 1); // ID state
wire BranchNE;
wire branch_taken ;
wire PC_enable = PCWrite || (PCWriteCond && branch_taken);
wire [31:0] PC_plus4 = ALUResult; // from IF stage
wire [31:0] shamt_ext = {27'b0, IR[10:6]};
assign branch_taken= BranchNE ? ~Zero : Zero;

// Program Counter
assign JumpAddr = {PC_plus4[31:28], IR[25:0], 2'b00};
assign PC_next =
    (PCSource == 2'b00) ? ALUResult :   // PC + 4
    (PCSource == 2'b01) ? ALUOut   :   // branch target
    (PCSource == 2'b10) ? JumpAddr   :   // jump target (simplified)
    32'b0;
Program_Counter pc(clk, reset,
    PC_enable ? PC_next : PC,
    PC);
    
// memory
wire [31:0] MemData;
Memory mem(clk, MemRead, MemWrite,
    (IorD)? ALUOut : PC,
    B_reg, MemData);

// IR / MDR
Reg32 ir(clk, reset, IRWrite, MemData, IR);
Reg32 mdr(clk, reset, 1'b1, MemData, MDR);

// reg file
Reg_file rf(clk, RegWrite,
    IR[25:21], IR[20:16],
    (RegDst)? IR[15:11] : IR[20:16],
    WriteData, A, B);

// A B registers
Reg32 Areg(clk, reset, ABWrite, A, A_reg);
Reg32 Breg(clk, reset, ABWrite, B, B_reg);

// immediate
ImmGen ig(IR, ImmExt);
ShiftLeft2 sh(ImmExt, ImmShift);

// ALU control
ALU_Control ac(ALUOp, IR[5:0], ALUCtrl);

// ALU input
wire [31:0] ALU_in2 =
    (ALUSrcB==2'b00)? B_reg :
    (ALUSrcB==2'b01)? 32'd4 :
    (ALUSrcB==2'b10)? ImmExt :
                  ImmShift;

ALU alu((ALUSrcA ? 
        ((ALUCtrl == 4'b1000) ? shamt_ext : A_reg) 
        : PC), ALU_in2, ALUCtrl, ALUResult, Zero);

// ALUOut
Reg32 aluout(clk, reset, 1'b1, ALUResult, ALUOut);

// writeback
assign WriteData = (MemtoReg)? MDR : ALUOut;

// control
Control_Unit cu(clk, reset, IR[31:26],
    PCWrite, PCWriteCond, IorD, MemRead, MemWrite, IRWrite,
    RegDst, MemtoReg, RegWrite,
    ALUSrcA, BranchNE,ALUSrcB, PCSource, ALUOp);
assign state = cu.state_out;
endmodule

//==============================================================================

// ============ TEST BENCH ================
module tb_multicycle;

reg clk, reset;

// Instantiate DUT
Multi_Cycle_Implementation uut(
    .clk(clk),
    .reset(reset)
);

// Clock generation
always #5 clk = ~clk;

// ================= INITIAL =================
initial begin
    clk = 0;
    reset = 1;

    $display("==== MULTI-CYCLE CPU TEST START ====");

    #20 reset = 0;

    // Run enough cycles
    #500;

    check_results();

    $display("==== TEST FINISHED ====");
    $finish;
end

// ================= MONITOR =================
always @(posedge clk) begin
    $display("T=%0t | PC=%h | IR=%h | A=%h | B=%h | ALU=%h | Zero=%b | state=%d",
        $time,
        uut.PC,
        uut.IR,
        uut.A_reg,
        uut.B_reg,
        uut.ALUResult,
        uut.Zero,
        uut.state
    );
end

// ================= TASK: CHECK RESULTS =================
task check_results;
begin
    $display("\n==== CHECKING RESULTS ====");

    // Registers
    $display("t1 = %d", uut.rf.regf[9]);   // $t1
    $display("t2 = %d", uut.rf.regf[10]);  // $t2
    $display("t3 = %d", uut.rf.regf[11]);  // $t3
    $display("t4 = %d", uut.rf.regf[12]);  // $t4
    $display("t5 = %d", uut.rf.regf[13]);  // $t5
    $display("t6 = %d", uut.rf.regf[14]);  // $t6

    // Memory
    $display("Mem[0] = %d", uut.mem.mem[0]);

    // ===== EXPECTED VALUES =====
    if (uut.rf.regf[9]  !== 5)
        $display("❌ ERROR: t1 incorrect");
    else
        $display("✅ t1 correct");

    if (uut.rf.regf[10] !== 10)
        $display("❌ ERROR: t2 incorrect");
    else
        $display("✅ t2 correct");

    if (uut.rf.regf[11] !== 15)
        $display("❌ ERROR: t3 incorrect (ADD failed)");
    else
        $display("✅ ADD correct");

    if (uut.mem.mem[0] !== 15)
        $display("❌ ERROR: SW failed");
    else
        $display("✅ SW correct");

    if (uut.rf.regf[12] !== 15)
        $display("❌ ERROR: LW failed");
    else
        $display("✅ LW correct");

    // BEQ should skip t5
    if (uut.rf.regf[13] !== 0)
        $display("❌ ERROR: BEQ failed (t5 should be 0)");
    else
        $display("✅ BEQ correct");

    if (uut.rf.regf[14] !== 42)
        $display("❌ ERROR: Final ADDI failed");
    else
        $display("✅ Final instruction correct");
$display("t7 (XOR) = %d", uut.rf.regf[15]);
$display("t8 (NOR) = %d", uut.rf.regf[16]);
$display("t9 (SLT) = %d", uut.rf.regf[17]);

if (uut.rf.regf[15] !== (5 ^ 10))
    $display("❌ XOR FAILED");
else
    $display("✅ XOR correct");

if (uut.rf.regf[16] !== ~(5 | 10))
    $display("❌ NOR FAILED");
else
    $display("✅ NOR correct");

if (uut.rf.regf[17] !== 1) // 5 < 10
    $display("❌ SLT FAILED");
else
    $display("✅ SLT correct");
end
endtask

endmodule
