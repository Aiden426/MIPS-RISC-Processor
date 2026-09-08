# 5-Stage Pipelined MIPS Processor

This directory contains the Verilog implementation of a 5-stage pipelined MIPS processor.

## Pipeline

The processor uses the classic five-stage pipeline:

```text
IF → ID → EX → MEM → WB
```

## Pipeline Registers

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

## Hazard Handling

The implementation includes:

### Data Forwarding

A forwarding unit detects dependencies between instructions and forwards results from later pipeline stages to the execute stage.

### Load-Use Hazard Detection

A hazard detection unit detects load-use dependencies and inserts a stall when required.

### Branch Handling

Branch instructions can cause instructions already in the pipeline to be flushed when the branch is taken.

### Jump Handling

Jump instructions also trigger pipeline flushing.

## Main Components

- Program Counter
- Instruction Memory
- Register File
- ALU
- ALU Control
- Control Unit
- Data Memory
- Forwarding Unit
- Hazard Detection Unit
- Pipeline Registers

## Verification

The testbench verifies:

- Register operations
- Load/store operations
- Load-use stalls
- Data forwarding
- Branch flushing
- Branch target execution

## Files

`Pipeline_Implementation.v` contains the processor implementation and testbench.