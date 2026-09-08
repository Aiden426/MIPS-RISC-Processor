`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2026 19:08:43
// Design Name: 
// Module Name: Single_Cycle_Implementation
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
                PC_out <=32'b0;
            else
                PC_out <= PC_in;
        end
endmodule

// ================= PC + 4 =================
module PCplus4(PC,NextPC);
    input [31:0] PC;
    output [31:0] NextPC;
    assign NextPC = 4 + PC;
endmodule

// =================== Instruction Memory ===================

module Instruction_memory(read_address, instruction_out);
    input [31:0] read_address;
    output [31:0] instruction_out;
    
    reg [31:0] I_mem[63:0];
    
    initial begin
        // Make non-zero values
        I_mem[0] = 32'h20010005; // addi $1,$0,5
        I_mem[1] = 32'h2002000A; // addi $2,$0,10

        // R-type tests
        I_mem[2] = 32'h00221820; // add $3,$1,$2
        I_mem[3] = 32'h00222022; // sub $4,$1,$2
        I_mem[4] = 32'h00222826; // xor $5,$1,$2
        I_mem[5] = 32'h00223027; // nor $6,$1,$2
        I_mem[6] = 32'h00023880; // sll $7,$2,2
        I_mem[7] = 32'h0022402A; // slt $8,$1,$2
  
        // Memory
        I_mem[8]  = 32'hac030000; // sw $3,0($0)
        I_mem[9]  = 32'h8c090000; // lw $9,0($0)
    
        // BEQ (should NOT take)
        I_mem[10] = 32'h10220001; // beq $1,$2,1
        I_mem[11] = 32'h00005020; // runs if BEQ not taken
    
        // BNE (should take)
        I_mem[12] = 32'h14220001; // bne $1,$2,1
        I_mem[13] = 32'h00005820; // skipped
        I_mem[14] = 32'h00006020; // executed

        // JUMP test
        I_mem[15] = 32'h08000012; // jump to 18
        I_mem[16] = 32'h00006820; // skipped
        I_mem[17] = 32'h00007020; // skipped
        I_mem[18] = 32'h00007820; // target
    end

 
    assign instruction_out = (read_address[7:2] < 19) ? I_mem[read_address[7:2]] : 32'b0;
endmodule

// ==================== Register ======================
module Reg_file(clk, reset,RegWrite, Rs1,Rs2,Rd,Write_data,read_data1, read_data2);
    input clk, reset,RegWrite; 
    input [4:0] Rs1,Rs2,Rd;
    input [31:0] Write_data;
    output [31:0] read_data1, read_data2;
    reg[31:0] Registers[31:0];
    integer k;
    always @(posedge clk or posedge reset)
    begin
        if(reset)
            begin
                for(k=0;k<32;k=k+1)begin
                    Registers[k] <= 32'b0;
                end
           end
       else if(RegWrite) begin
            Registers[Rd] <= Write_data;
      end 
   end 
assign read_data1 = Registers[Rs1];
assign read_data2 = Registers[Rs2];
endmodule

// Control Unit
module Control_Unit(
    input [5:0] opcode,
    output reg RegDst, ALUSrc, MemtoReg,
    output reg RegWrite, MemRead, MemWrite,
    output reg Branch, Jump, Bne,
    output reg [1:0] ALUOp
);

always @(*) begin
    // ✅ DEFAULT VALUES (VERY IMPORTANT)
    RegDst   = 0;
    ALUSrc   = 0;
    MemtoReg = 0;
    RegWrite = 0;
    MemRead  = 0;
    MemWrite = 0;
    Branch   = 0;
    Jump     = 0;
    Bne      = 0;
    ALUOp    = 2'b00;

    case(opcode)

        6'b000000: begin // R-type
            RegDst = 1;
            RegWrite = 1;
            ALUOp = 2'b10;
        end

        6'b100011: begin // lw
            ALUSrc = 1;
            MemtoReg = 1;
            RegWrite = 1;
            MemRead = 1;
        end

        6'b101011: begin // sw
            ALUSrc = 1;
            MemWrite = 1;
        end
        6'b001000: begin // ADDI
            ALUSrc = 1;
            RegWrite = 1;
            ALUOp = 2'b00; // ADD
        end 
        6'b000100: begin // beq
            Branch = 1;
            ALUOp = 2'b01;
        end

        6'b000101: begin // bne
            Bne = 1;
            ALUOp = 2'b01;
        end

        6'b000010: begin // jump
            Jump = 1;
        end

    endcase
end

endmodule

//ALU Control
module ALU_Control(input [1:0] ALUOp,
                   input [5:0] funct,
                   output reg [3:0] ALUCtrl);

always @(*) begin
    case(ALUOp)
        2'b00: ALUCtrl = 4'b0010; // add
        2'b01: ALUCtrl = 4'b0110; // sub (beq)
        2'b10: begin
            case(funct)
                6'b100000: ALUCtrl = 4'b0010; // add
                6'b100010: ALUCtrl = 4'b0110; // sub
                6'b100100: ALUCtrl = 4'b0000; // and
                6'b100101: ALUCtrl = 4'b0001; // or
                6'b100110: ALUCtrl = 4'b0011; // ✅ xor
                6'b100111: ALUCtrl = 4'b0100; // ✅ nor
                6'b000000: ALUCtrl = 4'b0101; // ✅ sll
                6'b101010: ALUCtrl = 4'b0111; // ✅ SLT
                default:   ALUCtrl = 4'b0000;
            endcase
        end
    endcase
end
endmodule

// ALU
module ALU(input [31:0] A, B,
           input [3:0] ALUCtrl,
           input [4:0] shamt,
           output reg [31:0] Result,
           output Zero);

    always @(*) begin
        case(ALUCtrl)
            4'b0000: Result = A & B;
            4'b0001: Result = A | B;
            4'b0010: Result = A + B;
            4'b0110: Result = A - B;
            4'b0011: Result = A ^ B;
            4'b0100: Result = ~(A | B);
            4'b0101: Result = B << shamt;
            4'b0111: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // ✅ SLT
            default: Result = 0;
        endcase
    end
assign Zero = (Result == 0);
endmodule

// Data Memory 
module Data_Memory(input clk, reset,
                   input MemWrite, MemRead,
                   input [31:0] addr, WriteData,
                   output [31:0] ReadData);

reg [31:0] mem[63:0];
integer i;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for(i=0;i<64;i=i+1)
            mem[i] <= 0;
    end
    else if (MemWrite)
        mem[addr[7:2]] <= WriteData;
end

assign ReadData = (MemRead) ? mem[addr[7:2]] : 0;
endmodule


//Main Module
//All moudules instantiate her...

// ================= MAIN TOP =================
module Single_Cycle_Implementation(input clk, reset);

wire [31:0] PC, NextPC, instr;
wire [31:0] ReadData1, ReadData2;
wire [31:0] ALU_B, ALUResult;
wire [31:0] MemData, WriteData;
wire [31:0] branch_addr, jump_addr, PC_next;
wire [31:0] ImmExt;

wire RegDst, ALUSrc, MemtoReg, RegWrite;
wire MemRead, MemWrite, Branch, Jump,Bne;
wire [1:0] ALUOp;
wire [3:0] ALUCtrl;
wire Zero;

// PC
Program_Counter pc(clk, reset, PC_next, PC);

// PC+4
PCplus4 pc4(PC, NextPC);

// Instruction Memory
Instruction_memory imem(PC, instr);

// Control
Control_Unit cu(.opcode(instr[31:26]), .RegDst(RegDst), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg), .RegWrite(RegWrite), 
 .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch),.Bne(Bne), .Jump(Jump), .ALUOp(ALUOp));
    
// Register select
wire [4:0] WriteReg;
assign WriteReg = (RegDst) ? instr[15:11] : instr[20:16];

// Register file
Reg_file rf(clk, reset, RegWrite,
            instr[25:21], instr[20:16],
            WriteReg, WriteData,
            ReadData1, ReadData2);

// Immediate
assign ImmExt = {{16{instr[15]}}, instr[15:0]};

// ALU control
ALU_Control alu_ctrl(ALUOp, instr[5:0], ALUCtrl);

// ALU input
assign ALU_B = (ALUSrc) ? ImmExt : ReadData2;

// ALU
ALU alu(ReadData1, ALU_B, ALUCtrl,instr[10:6], ALUResult, Zero);

// Data memory
Data_Memory dm(clk, reset, MemWrite, MemRead, ALUResult, ReadData2, MemData);

// Writeback
assign WriteData = (MemtoReg) ? MemData : ALUResult;

// Branch
assign branch_addr = NextPC + (ImmExt << 2);

// Jump
assign jump_addr = {NextPC[31:28], instr[25:0], 2'b00};

// PC select
assign PC_next = (Jump) ? jump_addr :
                 (Branch && Zero) ? branch_addr :
                 (Bne && ~Zero) ? branch_addr :
                 NextPC;
endmodule



// ================= TESTBENCH =================
module tb_top;

reg clk, reset;

// Instantiate DUT
Single_Cycle_Implementation uut(.clk(clk), .reset(reset));

// Clock generation
always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;

    // Apply reset
    #20 reset = 0;
end

// Monitor important signals
initial begin
    $display("Time\tPC\t\tInstr\t\tALURes\tZero\tJump\tBranch\tBne");

    $monitor("%0t\t%h\t%h\t%h\t%b\t%b\t%b\t%b",
        $time,
        uut.PC,
        uut.instr,
        uut.ALUResult,
        uut.Zero,
        uut.Jump,
        uut.Branch,
        uut.Bne
    );
end

// Dump waveform (VERY IMPORTANT for debugging)
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_top);
end

// Stop simulation
initial begin
    #600 $finish;
end

// ✅ FINAL CHECK AFTER EXECUTION
initial begin
    #290;
    $display("\n===== FINAL REGISTER VALUES =====");
    $display("R1 = %d", uut.rf.Registers[1]);
    $display("R2 = %d", uut.rf.Registers[2]);
    $display("R3 = %d", uut.rf.Registers[3]);
    $display("R4 = %d", uut.rf.Registers[4]);
    $display("R5 = %d", uut.rf.Registers[5]);

    $display("\n===== MEMORY VALUES =====");
    $display("MEM[0] = %d", uut.dm.mem[0]);
end
endmodule