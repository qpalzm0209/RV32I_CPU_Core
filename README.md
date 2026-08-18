# RV32I CPU Core V2 — Multi-cycle

기존 [RV32I_CPU_Core](https://github.com/qpalzm0209/RV32I_CPU_Core)의 single-cycle 데이터패스를 FSM 기반 multi-cycle 구조로 전환한 V2입니다. 기존에 지원하던 RV32I 명령 집합과 `rv32i_cpu` 외부 메모리 인터페이스는 유지하면서, 긴 조합 경로를 여러 클록으로 분할했습니다.

## V2에서 달라진 점

| 구분 | V1 single-cycle | V2 multi-cycle |
| --- | --- | --- |
| 제어기 | opcode 기반 조합 디코더 | 12-state FSM + state-qualified control |
| 명령어 실행 | 모든 단계를 1 cycle에 처리 | 3~5 cycle로 단계 분할 |
| 내부 상태 | PC, register file | PC + IR + OldPC + A/B + ALUOut + MDR |
| PC 갱신 | 매 cycle 갱신 | FETCH 및 branch/jump 상태에서만 갱신 |
| 메모리 쓰기 | 명령 디코드와 동시에 활성화 | MEM_WRITE 상태에서만 1 cycle pulse |
| 목적 | CPI 1의 단순 구조 | critical path 단축과 단계별 제어 명확화 |

## 상태 흐름

```text
FETCH -> DECODE -> ALU_EXEC -> ALU_WB -> FETCH       R/I ALU, AUIPC
                -> MEM_ADDR -> MEM_READ -> MEM_WB    Load
                            -> MEM_WRITE              Store
                -> BRANCH                            Branch
                -> LUI_WB                            LUI
                -> JUMP                              JAL
                -> JALR_EXEC                         JALR
```

FETCH에서 현재 명령어와 명령어 주소를 `IR`, `OldPC`에 저장하고 PC를 `PC+4`로 갱신합니다. 이후 단계는 IR에 저장된 명령을 사용하므로 instruction memory 출력이 다음 주소로 바뀌어도 실행 중인 명령은 유지됩니다.

### 명령어별 cycle 수

| 명령어 종류 | 상태 | Cycle |
| --- | --- | ---: |
| R-type / I-type ALU | FETCH → DECODE → ALU_EXEC → ALU_WB | 4 |
| AUIPC | FETCH → DECODE → ALU_EXEC → ALU_WB | 4 |
| Load | FETCH → DECODE → MEM_ADDR → MEM_READ → MEM_WB | 5 |
| Store | FETCH → DECODE → MEM_ADDR → MEM_WRITE | 4 |
| Branch | FETCH → DECODE → BRANCH | 3 |
| LUI | FETCH → DECODE → LUI_WB | 3 |
| JAL / JALR | FETCH → DECODE → JUMP/JALR_EXEC | 3 |

## 지원 명령어

- R-type: `ADD SUB SLL SLT SLTU XOR SRL SRA OR AND`
- I-type ALU: `ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI`
- Load: `LB LH LW LBU LHU`
- Store: `SB SH SW`
- Branch: `BEQ BNE BLT BGE BLTU BGEU`
- Upper/jump: `LUI AUIPC JAL JALR`

## 타이밍 검증

V1 README의 Basys3 100 MHz 결과는 WNS `-6.571 ns`, worst data path `16.520 ns`로 timing violation이었습니다.

V2는 Vivado 2020.2, `xc7a35tcpg236-1`, 10.000 ns clock에서 `rv32i_cpu`를 out-of-context로 합성·배치·배선했습니다.

| 항목 | V2 측정값 |
| --- | ---: |
| WNS | `+0.749 ns` |
| Worst data path delay | `9.100 ns` |
| Slice LUTs | 1,332 (6.40%) |
| Slice Registers | 1,230 (2.96%) |
| BRAM / DSP | 0 / 0 |

100 MHz 내부 register-to-register 제약은 충족했습니다. 다만 V1 수치와 V2 수치는 프로젝트 및 합성 경계가 완전히 같은 A/B 실험이 아니므로, 숫자 차이를 순수 아키텍처 개선량으로 단정하지 않습니다. V2 결과 역시 OOC 포트 위치와 상위 시스템 I/O delay가 없는 코어 내부 경로 결과이며, 최종 보드 timing sign-off는 실제 top/핀/메모리 조건을 포함해 다시 수행해야 합니다.

## 검증

네 개의 self-checking test를 사용합니다.

- `tb_multicycle_timing`: ALU 명령의 DECODE/EXECUTE/WRITEBACK 동안 PC 유지
- `tb_rv32i_isa`: 지원 명령 37개의 register/data-memory signature
- `tb_control_flow_edges`: not-taken/역방향 branch, JAL link, 홀수 JALR target 정렬
- `tb_illegal_instruction`: 잘못된 funct 조합의 register/PC/memory side effect 차단

인식하지 않는 인코딩은 trap 없이 다음 명령으로 넘기며 architectural state를 변경하지 않습니다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_synth_check.ps1
```

도구 경로는 기본적으로 `C:\Xilinx\Vivado\2020.2\bin`을 사용합니다. 다른 버전이나 설치 위치에서는 두 PowerShell 스크립트의 `$vivadoBin` 또는 `$vivado` 값을 변경하면 됩니다.

## 프로젝트 구조

```text
RV32I_CPU_Core_v2
├─ define.vh                    opcode/control definitions
├─ rv32i_cpu.sv                 top-level CPU + multi-cycle FSM
├─ rv32i_datapath.sv            staged datapath and architectural state
├─ instruction_mem.sv           asynchronous instruction ROM
├─ data_mem.sv                  byte-addressed load/store memory
├─ rv32i_top.sv                 CPU and memory integration
├─ riscv_prg.mem                small default demonstration program
├─ tests/
│  ├─ tb_multicycle_timing.sv
│  ├─ tb_rv32i_isa.sv
│  ├─ tb_control_flow_edges.sv
│  └─ tb_illegal_instruction.sv
├─ scripts/
│  ├─ run_tests.ps1
│  ├─ check_synth.tcl
│  └─ run_synth_check.ps1
```

## 성능 해석 시 주의점

Multi-cycle은 최대 클록 주파수와 단계별 제어를 개선하지만 CPI는 증가합니다. 100 MHz에서 이 구현의 이상적인 처리율은 ALU 약 25 MIPS, load 약 20 MIPS, branch/jump 약 33.3 MIPS입니다. 따라서 V2의 핵심 성과는 “항상 처리량이 더 높다”가 아니라, 100 MHz timing closure, 짧아진 단계별 critical path, 하드웨어 재사용, 그리고 이후 wait-state/exception 등을 추가하기 쉬운 제어 구조입니다.
