# 🚀 AMBA AHB-Lite Protocol Implementation

### Author
**Khaled Ahmed Hamed**  
📌 Summer 2025 – Digital Communication and Digital Design Internship  

---

## 📖 Project Overview
This project implements and verifies a **complete AMBA®3 AHB-Lite system** using **Verilog HDL**.  
The design demonstrates the **AMBA bus protocol** concepts of:  
- **High-performance pipelined bus transfers**  
- **Burst and single transfers**  
- **Handshake-based synchronization**  
- **Error handling**  

### 🔑 Key Features
- Single **AHB-Lite Master** with FSM-based control  
- Three **AHB-Lite Slaves**, each mapped to 1KB memory  
- **Address Decoder** for slave selection  
- **Read Multiplexor** for returning slave data  
- **Self-checking Testbenches** for:
  - Master
  - Slave
  - Complete SoC  

---

## 🏗️ System Architecture
The AMBA AHB-Lite implementation follows the ARM **IHI0033A** specification.

<img width="576" height="286" alt="image" src="https://github.com/user-attachments/assets/3b60770f-cd69-4aee-81d9-c2c0d69eaeba" />

### 🔹 Global Signals
- **HCLK**: Common clock for all AHB-Lite modules (10 ns period)  
- **HRESETn**: Active-low asynchronous reset  

### 🔹 Master
<img width="576" height="196" alt="image" src="https://github.com/user-attachments/assets/04228ef6-0f35-4652-ba6b-e0814dbdb049" />

- Generates **address, control, and data signals**  
- Implements a **4-state FSM**:  
  - `IDLE` → `NONSEQ` → `SEQ` → `BUSY`
    
    <img width="576" height="472" alt="image" src="https://github.com/user-attachments/assets/ac50050c-bb1e-47bd-b9d3-5c744fa4869d" />

- Supports:
  - Transfer types: `HTRANS[1:0]` (IDLE, NONSEQ, SEQ, BUSY)  
  - Burst types: `SINGLE`, `INCR4`, `INCR8`, `INCR16`  
  - Transfer sizes: byte, halfword, word  

### 🔹 Slave
<img width="528" height="274" alt="image" src="https://github.com/user-attachments/assets/3c8ae536-eb9b-49a8-a4df-c8eb1b3e6691" />

- Each slave responds to transactions mapped to its address region.  
- **Memory Mapping**:
  | Slave | Base Address   | Memory Size |
  |-------|----------------|-------------|
  | 0     | `0x4000_0000` | 1 KB        |
  | 1     | `0x4000_2000` | 1 KB        |
  | 2     | `0x4000_4000` | 1 KB        |
- Features:
  - Misalignment detection (Word aligned to 4B, Halfword aligned to 2B)  
  - Error response via **HRESP = 1**  
  - Supports **byte, halfword, word accesses**  

### 🔹 Interconnect
<img width="386" height="262" alt="image" src="https://github.com/user-attachments/assets/160a9226-7d6d-49fc-b2e9-bd4cef7bdb71" />

- **Decoder**: Selects one slave based on upper address bits (`HADDR[13:14]`).  
- **Multiplexor**: Routes `HRDATA`, `HRESP`, and `HREADYOUT` back to the master.  

## 🔧 Verilog Design Description
- **AHB-Lite Slave**
  - Implements **alignment checks** (word → 4B, halfword → 2B).  
  - Returns error (`HRESP=1`) for misaligned/unsupported accesses.  
  - Supports pipelined transfers (no wait states under normal ops).  

- **AHB-Lite Master**
  - FSM-based design with **single & burst transfers (INCR4, INCR8, INCR16)**.  
  - Handles **wait states**, **error recovery**, and **boundary violations**.  

- **Interconnection Module**
  - Centralized multiplexer-based router.  
  - Ensures only the selected slave receives transactions.  

---

## 🧪 Testbench & Simulation
- **Clock**: 10 ns period  
- **Reset**: Active-low asynchronous reset  

### Directed Test Cases
| Operation | Address      | Data        | Result |
|-----------|-------------|-------------|--------|
| Write     | `0x40000000` | `0x11223344` | PASS   |
| Read      | `0x40000000` | `0x11223344` | PASS   |
| Write     | `0x40002000` | `0xDEADBEEF` | PASS   |
| Read      | `0x40002000` | `0xDEADBEEF` | PASS   |
| Write     | `0x40004000` | `0xAABBCCDD` | PASS   |
| Read      | `0x40004000` | `0xAABBCCDD` | PASS   |

✔ Verified **single & burst transfers, pipelining, and error handling**.

---

## 🚀 Future Work
- Extend to **multi-master systems**
- Add **wrapping bursts (WRAP4/8/16)**, locked transfers, and protection
- **UVM-based verification environment** with coverage-driven testing
- **Randomized constrained testing**
- Integrate **assertions & formal verification**
- Backend flow to generate **GDSII**

---

## ✅ Conclusion
This project delivers a **fully functional AHB-Lite implementation** in Verilog with:
- A single master
- Multiple memory-mapped slaves
- Protocol-compliant interconnect
- Verified through **directed simulation**

For full protocol specification:  
📄 [ARM IHI0033A: AMBA AHB-Lite Specification](https://www.eecs.umich.edu/courses/eecs373/readings/ARM_IHI0033A_AMBA_AHB-Lite_SPEC.pdf)

---
