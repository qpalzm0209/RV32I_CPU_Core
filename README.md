# RV32I CPU Core

## 프로젝트 개요

RISC-V RV32I instruction subset을 실행하는 CPU core를 Control Unit, Datapath, Memory 구조로 구현한 프로젝트입니다.  
**발표자료: https://drive.google.com/file/d/1lJpqC5rr4aY5bQ42WpIgWDJ5MNwCTp14/view?usp=drive_link**

## 목표 동작

- Instruction memory에서 명령어를 fetch합니다.
- Control Unit이 opcode/funct 필드를 해석해 제어 신호를 생성합니다.
- Datapath가 register file, ALU, branch compare, immediate extender를 통해 명령어를 실행합니다.
- Data memory를 통해 load/store 명령을 처리합니다.
- PC update 로직으로 sequential/branch/jump 흐름을 수행합니다.

## 기술 스택

| 구분 | 내용 |
| --- | --- |
| 핵심 개념 | RISC-V RV32I, CPU datapath, control unit, ALU, register file, branch, memory access |
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

- `tb_rv32i_cpu`, `rv32i_top_sim`을 통해 instruction 실행 결과와 register/memory 동작을 확인할 수 있습니다.
