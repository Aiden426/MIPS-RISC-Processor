# Single-Cycle MIPS Processor

This directory contains the Verilog implementation of a single-cycle MIPS processor.

## Architecture

Each instruction completes its execution within a single clock cycle.

### Main Components

- Program Counter
- PC + 4 logic
- Instruction Memory
- Register File
- Control Unit
- ALU Control
- ALU
- Data Memory
- Immediate Extension
- Branch logic
- Jump logic

## Supported Instructions

The test program includes:

- ADD
- SUB
- XOR
- NOR
- SLL
- SLT
- LW
- SW
- ADDI
- BEQ
- BNE
- J

## Files

`Single_Cycle_Implementation.v` contains the processor modules and testbench.