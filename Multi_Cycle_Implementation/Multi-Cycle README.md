# Multi-Cycle MIPS Processor

This directory contains the Verilog implementation of a multi-cycle MIPS processor.

## Architecture

Instruction execution is divided across multiple clock cycles using a finite-state control unit.

## Control States

The processor contains states for:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- R-Type Execute
- Memory Address Calculation
- Memory Read
- Memory Write
- Load Write-Back
- Register Write-Back
- Branch
- Jump

## Main Components

- Program Counter
- Shared Memory
- Register File
- ALU
- ALU Control
- Immediate Generator
- Shift-Left-2 Unit
- Intermediate Registers
- Control FSM

## Verification

The testbench verifies operations including:

- ADDI
- ADD
- SW
- LW
- BEQ
- XOR
- NOR
- SLT

## Files

`Multi_Cycle_Implementation.v` contains the processor implementation and testbench.