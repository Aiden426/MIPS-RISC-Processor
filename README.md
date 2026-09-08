# MIPS RISC Processor Implementations

Verilog implementations of a MIPS-based RISC processor developed at three different microarchitectural levels:

- Single-Cycle Processor
- Multi-Cycle Processor
- 5-Stage Pipelined Processor

## Project Overview

This project demonstrates the evolution of a MIPS processor from a simple single-cycle datapath to a multi-cycle implementation and finally to a pipelined architecture with hazard handling.

## Implementations

### 1. Single-Cycle MIPS

The single-cycle implementation executes each instruction within one clock cycle.

Features include:

- Program Counter
- Instruction Memory
- Register File
- ALU
- ALU Control
- Control Unit
- Data Memory
- Branch instructions
- Jump instructions
- Immediate instructions

Supported/tested instructions include:

`ADD`, `SUB`, `XOR`, `NOR`, `SLL`, `SLT`, `LW`, `SW`, `ADDI`, `BEQ`, `BNE`, and `J`.

### 2. Multi-Cycle MIPS

The multi-cycle implementation divides instruction execution into multiple clock cycles using a finite-state machine.

Major states include:

- Instruction Fetch
- Instruction Decode
- R-Type Execute
- Memory Address Calculation
- Memory Read
- Memory Write
- Load Write-Back
- Register Write-Back
- Branch
- Jump

The implementation uses intermediate registers such as the IR, MDR, A, B, and ALUOut registers.

### 3. 5-Stage Pipelined MIPS

The pipelined implementation uses the classic five-stage pipeline:

```text
IF → ID → EX → MEM → WB
```

Pipeline registers include:

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

The processor also implements:

- Data forwarding
- Load-use hazard detection
- Pipeline stalls
- Branch flushing
- Jump flushing
- Branch handling

## Repository Structure

```text
MIPS-RISC-Processor/
│
├── README.md
│
├── single-cycle/
│   ├── Single_Cycle_Implementation.v
│   └── README.md
│
├── multi-cycle/
│   ├── Multi_Cycle_Implementation.v
│   └── README.md
│
└── pipeline/
    ├── Pipeline_Implementation.v
    └── README.md
```

## HDL

Verilog HDL

## Simulation

The implementations were developed and tested using Verilog simulation.

Each implementation contains its own testbench for functional verification.

## Author

Utkarsh Raj