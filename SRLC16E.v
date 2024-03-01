`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// SRLC16E primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module SRLC16E
#(
    parameter [15:0] INIT = 16'h0,
    parameter  [0:0] IS_CLK_INVERTED = 1'b0
)
(
    // Clock
    input  wire       CLK,
    // Clock enable
    input  wire       CE,
    // Bit output position
    input  wire       A0, A1, A2, A3,
    // Data in
    input  wire       D,
    // Data out
`ifdef FAST_IQ
    output wire       Q,
`else
    output wire       Q /* verilator public_flat_rd */,
`endif
    // Cascading data out
`ifdef FAST_IQ
    output wire       Q15
`else
    output wire       Q15 /* verilator public_flat_rd */,
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 0;
`endif

    // 32-bit shift register
    reg  [15:0] _r_srl;

    // Bit position
    wire  [3:0] _w_addr = { A3, A2, A1, A0 };

    // Power-up value
    initial begin
        _r_srl = INIT;
    end

    // Shifter logic
    generate
        if (IS_CLK_INVERTED) begin : GEN_CLK_NEG
            always @(negedge CLK) begin : SHIFTER_16B

                if (CE) begin
                    _r_srl <= { _r_srl[14:0], D };
                end
            end
        end
        else begin : GEN_CLK_POS
            always @(posedge CLK) begin : SHIFTER_16B

                if (CE) begin
                    _r_srl <= { _r_srl[14:0], D };
                end
            end
        end
    endgenerate

    // Data out
`ifdef FAST_IQ
    reg Q_f /* verilator public_flat_rw */ = 1'b0;
    reg Q_v /* verilator public_flat_rw */ = 1'b0;
    assign Q   = Q_f ? Q_v : _r_srl[_w_addr];
`else
    assign Q   = _r_srl[_w_addr];
`endif

    // Cascading data out
`ifdef FAST_IQ
    reg Q15_f /* verilator public_flat_rw */ = 1'b0;
    reg Q15_v /* verilator public_flat_rw */ = 1'b0;
    assign Q15 = Q15_f ? Q15_v : _r_srl[15];
`else
    assign Q15 = _r_srl[15];
`endif

endmodule
/* verilator coverage_on */
