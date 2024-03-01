`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// LDPE primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module LDPE
#(
    parameter INIT = 1'b0
)
(
    // Asynchronous preset
    input   wire PRE,
    // Latch
    input   wire G,
    // Latch enable
    input   wire GE,
    // Data in
    input   wire D,
    // Data out
`ifdef FAST_IQ
    output  wire Q
`else
    output  wire Q /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 0;
`endif
    reg _r_Q;

    initial begin : INIT_STATE
        _r_Q = INIT[0];
    end

    always @(PRE or G or GE or D) begin : LATCH

        if (PRE) begin
            _r_Q = 1'b1;
        end
        else if (G & GE) begin
            _r_Q = D;
        end
    end

`ifdef FAST_IQ
    reg Q_f /* verilator public_flat_rw */ = 1'b0;
    reg Q_v /* verilator public_flat_rw */ = 1'b0;
    assign Q = Q_f ? Q_v : _r_Q;
`else
    assign Q = _r_Q;
`endif

endmodule
/* verilator coverage_on */
