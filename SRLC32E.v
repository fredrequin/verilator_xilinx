`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// SRLC32E primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module SRLC32E
#(
    parameter [31:0] INIT = 32'h0,
    parameter  [0:0] IS_CLK_INVERTED = 1'b0
)
(
    // Clock
    input  wire       CLK,
    // Clock enable
    input  wire       CE,
    // Bit output position
    input  wire [4:0] A,
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
    output wire       Q31
`else
    output wire       Q31 /* verilator public_flat_rd */,
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 0;
`endif

    // 32-bit shift register
    reg  [31:0] _r_srl;

    // Power-up value
    initial begin
        _r_srl = INIT;
    end

    // Shifter logic
    generate
        if (IS_CLK_INVERTED) begin : GEN_CLK_NEG
            always @(negedge CLK) begin : SHIFTER_32B

                if (CE) begin
                    _r_srl <= { _r_srl[30:0], D };
                end
            end
        end
        else begin : GEN_CLK_POS
            always @(posedge CLK) begin : SHIFTER_32B

                if (CE) begin
                    _r_srl <= { _r_srl[30:0], D };
                end
            end
        end
    endgenerate

    // Data out
`ifdef FAST_IQ
    reg Q_f /* verilator public_flat_rw */ = 1'b0;
    reg Q_v /* verilator public_flat_rw */ = 1'b0;
    assign Q   = Q_f ? Q_v : _r_srl[A];
`else
    assign Q   = _r_srl[A];
`endif

    // Cascading data out
`ifdef FAST_IQ
    reg Q31_f /* verilator public_flat_rw */ = 1'b0;
    reg Q31_v /* verilator public_flat_rw */ = 1'b0;
    assign Q31 = Q31_f ? Q31_v : _r_srl[31];
`else
    assign Q31 = _r_srl[31];
`endif

endmodule
/* verilator coverage_on */
