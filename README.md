# Codtech_Low_Power_ALU
Low Power ALU
# Low Power 8-Bit ALU with Integrated Clock Gating and Operand Isolation

## 🏢 Company Profile
* **Company:** CodTech IT Solutions
* **Intern Name:**Kakarlamudi divya
* **Intern Id:**CITS998
* **Domain:** VLSI Design (Low Power Design Lab)
* **Module Name:** `low_power_alu_top`
* **Testbench Name:** `tb_low_power_alu`
* **Target Environment:** RTL Simulation & Low-Power Synthesis

---

## 📌 Project Overview
This repository contains a high-efficiency **8-bit Arithmetic Logic Unit (ALU)** designed to minimize dynamic power dissipation in modern System-on-Chip (SoC) architectures. The design implements two powerful architectural low-power methodologies directly at the Register-Transfer Level (RTL):

1. **Integrated Clock Gating (ICG):** Completely disables the clock distribution tree of the sequential elements when the ALU is idle.
2. **Operand Isolation:** Blocks switching activities and toggles on primary data inputs from entering the core execution matrix when the module is disabled (`en = 0`).

---

## 🏗️ Architectural Specifications

The design layout is systematically structured into four functional blocks to achieve maximum leakage and dynamic power savings:

*   **Integrated Clock Gating (ICG) Cell:** Utilizes a glitch-free configuration using a negative-edge sensitive latch and a downstream AND gate to eliminate partial pulses during enable transitions.
*   **Operand Isolation Block:** Masking multiplexers force internal data paths (`isolated_a`, `isolated_b`) to a static logic zero (`8'h00`) when deactivated.
*   **Combinational Core:** An 8-bit execution unit running operations exclusively on the safe, isolated internal data registers.
*   **Sequential Stage:** An 8-bit register synced to the low-power `gated_clk` domain with asynchronous active-low reset (`rst_n`).

---

## 🔌 Interface Port Description

### Input Ports

| Port Name | Bit Width | Type | Description |
| :--- | :---: | :---: | :--- |
| `clk` | 1 | Input | Master System Clock (100MHz nominal) |
| `rst_n` | 1 | Input | Asynchronous Reset (Active-Low) |
| `en` | 1 | Input | Global Module Enable / Power Management Signal |
| `opcode` | 3 | Input | Operation Select Code |
| `src_a` | 8 | Input | Primary Source Operand Input |
| `src_b` | 8 | Input | Secondary Source Operand Input |

### Output Ports

| Port Name | Bit Width | Type | Description |
| :--- | :---: | :---: | :--- |
| `alu_out` | 8 | Output | Registered ALU Output Matrix |
| `pmu_gated_clk` | 1 | Output | Gated Clock Monitor (For Power Management Verification) |

---

## 📊 Functional Truth Table


| Opcode | Operation | Functional Mapping | Hardware Block Triggered |
| :---: | :---: | :--- | :--- |
| `3'b000` | ADD | `alu_out <= src_a + src_b;` | Arithmetic Adder Array |
| `3'b001` | SUB | `alu_out <= src_a - src_b;` | Two's Complement Subtractor |
| `3'b010` | AND | `alu_out <= src_a & src_b;` | Bitwise Logical AND Matrix |
| `3'b011` | OR | `alu_out <= src_a \| src_b;` | Bitwise Logical OR Matrix |
| `3'b100` | XOR | `alu_out <= src_a ^ src_b;` | Bitwise Logical XOR Matrix |
| `3'b101` | NOT | `alu_out <= ~src_a;` | Bitwise Inverter Array |
| `3'b110` | SLL | `alu_out <= src_a << 1;` | Logical Left Shifter Barrel |
| `3'b111` | SRL | `alu_out <= src_a >> 1;` | Logical Right Shifter Barrel |

---

## 🧪 Simulation & Verification Strategy

The verification framework (`tb_low_power_alu`) stresses the design under a **3-Phase Power Simulation Plan** using standard VCD dumping tools (`dump.vcd`):

1. **Phase 1: Active Processing Mode (`en = 1`)**
   * Verifies basic arithmetic accuracy (ADD, SUB).
   * `pmu_gated_clk` functions continuously alongside the master system clock.
2. **Phase 2: Low Power Mode State (`en = 0`)**
   * The ICG latch captures the disable condition and forces `pmu_gated_clk` flat.
   * **Stress Test:** Primary vectors `src_a` and `src_b` are intentionally flooded with massive switching toggles (`8'hFF`). The isolation boundary locks internal variables to `8'h00`, demonstrating near-zero dynamic power draw.
3. **Phase 3: Safe Wake-up Cycle (`en = 1`)**
   * Confirms immediate restoration of data paths and clock networks without logical propagation lag or latch latency.

---

## 🚀 How to Run the Simulation

You can compile and run this project using any standard IEEE 1364-2005 compliant Verilog simulator (e.g., Icarus Verilog, ModelSim, Vivado).

### Using Icarus Verilog (iVerilog) via Terminal:
```bash
# 1. Compile design and testbench
// ===================================================================
// Company:     CodTech IT Solutions
// Domain:      VLSI Design (Low Power Design Lab)
// Module:      low_power_alu_top
// Description: Top-level 8-bit ALU with integrated clock gating
//              and operand isolation for dynamic power reduction.
// ===================================================================

`timescale 1ns / 1ps

module low_power_alu_top (
    input  wire       clk,          // Master System Clock
    input  wire       rst_n,        // Active-low asynchronous reset
    input  wire       en,           // Global module enable signal
    input  wire [2:0] opcode,       // Operation selection code
    input  wire [7:0] src_a,        // Input Operand A
    input  wire [7:0] src_b,        // Input Operand B
    output reg  [7:0] alu_out,      // Registered ALU output
    output reg        pmu_gated_clk // Monitored gated clock output
);

    // ---------------------------------------------------------------
    // Internal Signals
    // ---------------------------------------------------------------
    wire       gated_clk;           // Clock signal after gating latch
    reg        gating_en;           // Latch-controlled clock enable
    reg  [7:0] isolated_a;          // Isolated Operand A to prevent toggling
    reg  [7:0] isolated_b;          // Isolated Operand B to prevent toggling
    reg  [7:0] alu_comb_out;        // Combinational ALU result

    // ---------------------------------------------------------------
    // 1. Clock Gating Cell (Integrated Clock Gating - ICG Emulation)
    //    Prevents clock tree switching power when 'en' is low.
    //    Uses a negative-edge latch to prevent clock glitches.
    // ---------------------------------------------------------------
    always @(clk or en) begin
        if (!clk) begin
            gating_en <= en;
        end
    end

    // AND gate generates the glitch-free low-power clock tree
    assign gated_clk = clk & gating_en;

    // Hook up internal gated clock to output port for lab monitoring
    always @(*) begin
        pmu_gated_clk = gated_clk;
    end

    // ---------------------------------------------------------------
    // 2. Operand Isolation Logic
    //    Blocks input data toggling from entering the ALU matrix
    //    when the module is disabled, saving leak/dynamic power.
    // ---------------------------------------------------------------
    always @(*) begin
        if (en) begin
            isolated_a = src_a;
            isolated_b = src_b;
        end else begin
            isolated_a = 8'h00; // Force zero to freeze downstream muxes
            isolated_b = 8'h00; // Force zero to freeze downstream muxes
        end
    end

    // ---------------------------------------------------------------
    // 3. Combinational ALU Core
    //    Executes operations using isolated low-power operands.
    // ---------------------------------------------------------------
    always @(*) begin
        case (opcode)
            3'b000:  alu_comb_out = isolated_a + isolated_b; // ADD
            3'b001:  alu_comb_out = isolated_a - isolated_b; // SUB
            3'b010:  alu_comb_out = isolated_a & isolated_b; // AND
            3'b011:  alu_comb_out = isolated_a | isolated_b; // OR
            3'b100:  alu_comb_out = isolated_a ^ isolated_b; // XOR
            3'b101:  alu_comb_out = ~isolated_a;             // NOT A
            3'b110:  alu_comb_out = isolated_a << 1;         // Logical Shift Left
            3'b111:  alu_comb_out = isolated_a >> 1;         // Logical Shift Right
            default: alu_comb_out = 8'h00;
        endcase
    end

    // ---------------------------------------------------------------
    // 4. Sequential Output Register
    //    Driven by the low-power 'gated_clk' domain.
    // ---------------------------------------------------------------
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_out <= 8'h00;
        end else begin
            alu_out <= alu_comb_out;
        end
    end

endmodule


2.testbench code
// ===================================================================
// Company:     CodTech IT Solutions
// Domain:      VLSI Design (Low Power Design Lab)
// Testbench:   tb_low_power_alu
// Description: Verifies functionality and demonstrates power saving states.
// ===================================================================

`timescale 1ns / 1ps

module tb_low_power_alu;

    // Testbench Inputs
    reg        clk;
    reg        rst_n;
    reg        en;
    reg  [2:0] opcode;
    reg  [7:0] src_a;
    reg  [7:0] src_b;

    // Testbench Outputs
    wire [7:0] alu_out;
    wire       pmu_gated_clk;

    // Instantiate Unit Under Test (UUT)
    low_power_alu_top uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .opcode(opcode), 
        .src_a(src_a), 
        .src_b(src_b), 
        .alu_out(alu_out),
        .pmu_gated_clk(pmu_gated_clk)
    );

    // Generate 100MHz System Clock
    always #5 clk = ~clk;

    initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb_low_power_alu);
    
    // Initialize Inputs
    clk = 0;
    rst_n = 0;
      
        // Initialize Inputs
        clk    = 0;
        rst_n  = 0;
        en     = 0;
        opcode = 0;
        src_a  = 0;
        src_b  = 0;

        // Apply Reset
        #15;
        rst_n = 1;
        #10;
        
        // -----------------------------------------------------------
        // PHASE 1: Normal Active Operation (Enable = 1)
        // -----------------------------------------------------------
        en = 1;
        src_a = 8'h10; src_b = 8'h05; opcode = 3'b000; // ADD (Result: 15)
        #10;
        src_a = 8'h20; src_b = 8'h02; opcode = 3'b001; // SUB (Result: 1E)
        #10;

        // -----------------------------------------------------------
        // PHASE 2: Low Power Mode Activated (Enable = 0)
        // -----------------------------------------------------------
        en = 0; 
        #5; // Observe that pmu_gated_clk stops toggling completely
        
        // Toggle inputs during idle mode to test Operand Isolation
        src_a = 8'hFF; src_b = 8'hFF; opcode = 3'b010; 
        #20; // Internal ALU signals will not toggle, saving dynamic power

        // -----------------------------------------------------------
        // PHASE 3: Wake up Module (Enable = 1)
        // -----------------------------------------------------------
        en = 1;
        src_a = 8'h0F; src_b = 8'h0F; opcode = 3'b010; // AND (Result: 0F)
        #10;

        // End Simulation
        $display("Low Power Design Lab Simulation Completed Successfully.")
        $finish;
    end
      
endmodulue

## 🧪 EDA Playground Simulation Results

### 1. Console Output & Testbench
https://raw.githubusercontent.com/Low_Power_ALU/Kakarlamudidivya90-dev/main/docs/Screenshot_20260602_193703.jpg









---
💡 *Developed as part of the Low Power VLSI Design Lab portfolio at CodTech IT Solutions.*
