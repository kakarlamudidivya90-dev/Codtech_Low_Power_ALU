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
