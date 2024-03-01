`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// FDSE primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module FDSE
#(
    parameter [0:0] IS_C_INVERTED = 1'b0,
    parameter [0:0] IS_D_INVERTED = 1'b0,
    parameter [0:0] IS_S_INVERTED = 1'b0,
    parameter [0:0] INIT          = 1'b1
)
(
    // Clock
    input  wire C,
    // Clock enable
    input  wire CE,
    // Synchronous set
    input  wire S,
    // Data in
    input  wire D,
    // Data out
`ifdef FAST_IQ
    output wire Q
`else
    output wire Q /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 0;
`endif
    reg _r_Q;

    wire _w_D = D ^ IS_D_INVERTED;
    wire _w_S = S ^ IS_S_INVERTED;

    initial begin : INIT_STATE
        _r_Q = INIT[0];
    end

    generate
        if (IS_C_INVERTED) begin : GEN_CLK_NEG
            always @(negedge C) begin

                if (_w_S) begin
                    _r_Q <= 1'b1;
                end
                else if (CE) begin
                    _r_Q <= _w_D;
                end
            end
        end
        else begin : GEN_CLK_POS
            always @(posedge C) begin

                if (_w_S) begin
                    _r_Q <= 1'b1;
                end
                else if (CE) begin
                    _r_Q <= _w_D;
                end
            end
        end
    endgenerate

`ifdef FAST_IQ
    reg Q_f /* verilator public_flat_rw */ = 1'b0;
    reg Q_v /* verilator public_flat_rw */ = 1'b0;
    assign Q = Q_f ? Q_v : _r_Q;
`else
    assign Q = _r_Q;
`endif

endmodule
/* verilator coverage_on */
