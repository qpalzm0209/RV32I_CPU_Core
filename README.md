# RV32I CPU Core

## 프로젝트 개요

RISC-V RV32I integer instruction subset을 실행하는 CPU core를 Control Unit, Datapath, Instruction Memory, Data Memory 구조로 구현한 프로젝트입니다.
PC 기반 instruction fetch부터 decode, execute, memory access, write-back, next PC update까지의 명령 실행 흐름을 SystemVerilog RTL로 구성했습니다.
[발표자료 PDF](https://drive.google.com/file/d/1lJpqC5rr4aY5bQ42WpIgWDJ5MNwCTp14/view?usp=drive_link)

## 목표 동작

- Instruction memory에서 명령어를 fetch합니다.
- Control Unit이 opcode/funct 필드를 해석해 제어 신호를 생성합니다.
- Datapath가 register file, ALU, branch compare, immediate extender를 통해 명령어를 실행합니다.
- R-type `ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND`와 I-type ALU immediate 명령을 실행합니다.
- `LB/LH/LW/LBU/LHU`, `SB/SH/SW`를 통해 byte-addressed little-endian data memory를 load/store합니다.
- `BEQ/BNE/BLT/BGE/BLTU/BGEU`, `LUI/AUIPC`, `JAL/JALR`의 PC update 흐름을 수행합니다.
- 32 x 32-bit register file에서 `x0`을 항상 `0x00000000`으로 유지하고, reset 시 register file과 data memory를 초기화합니다.
- Data memory는 128개의 byte로 구성되며, load 명령은 폭에 따라 sign/zero extension을 적용합니다.

실행할 프로그램은 simulation working directory의 `riscv_prg.mem` 파일에서 `$readmemh`로 instruction memory에 로드합니다.

## 기술 스택

| 구분 | 내용 |
| --- | --- |
| 핵심 개념 | RISC-V RV32I subset, CPU datapath, control unit, ALU, register file, branch/jump, load/store |
| 사용 장비 | Basys3 FPGA 대상 설계, simulation 환경 |
| 사용 언어 | SystemVerilog |
| 개발 도구 | Vivado, HDL simulation testbench |

## 시스템 구조

```text
rv32i_top
├─ instruction_mem
├─ data_mem
└─ rv32i_cpu
   ├─ control_unit
   └─ rv32i_datapath
      ├─ program_counter
      ├─ pc_adder
      ├─ register_file
      ├─ imm_extender
      ├─ alu
      ├─ branch_compare
      ├─ state_register
      ├─ mux_2x1
      └─ mux_4x1
```

- `rv32i_top`: CPU core와 instruction/data memory를 연결하는 최상위 모듈입니다.
- `rv32i_cpu`: Control Unit과 Datapath를 묶어 instruction 실행 흐름을 구성합니다.
- `control_unit`: opcode 기반으로 ALU operation, memory write, register write, PC source 등을 생성합니다.
- `rv32i_datapath`: PC, register file, ALU, immediate, branch 비교 로직을 포함합니다.
- `instruction_mem`: 실행할 instruction을 제공합니다.
- `data_mem`: load/store 명령의 데이터 저장소 역할을 합니다.

## 검증 방식

- `tb_rv32i_cpu`, `rv32i_top_sim`에서 clock/reset을 인가하고 instruction 실행에 따른 PC, register file, ALU, data memory 변화를 파형으로 확인합니다.
- `instruction_mem.sv`의 예제 instruction image는 ALU, load/store 폭과 sign extension, signed/unsigned branch, LUI/AUIPC/JAL/JALR 조건을 포함하도록 구성할 수 있습니다.
- `riscv_prg.mem`에 원하는 RV32I instruction image를 준비하면 동일한 RTL에서 프로그램별 동작을 재현할 수 있습니다.
