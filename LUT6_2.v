`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// LUT6_2 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module LUT6_2
#(
    parameter [63:0] INIT = 64'h0000000000000000
)
(
    input  wire I0, I1, I2, I3, I4, I5,
`ifdef FAST_IQ
    output wire O5,
`else
    output wire O5 /* verilator public_flat_rd */,
`endif
`ifdef FAST_IQ
    output wire O6
`else
    output wire O6 /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 1;
`endif
    wire [5:0] _w_idx_5 = { 1'b0, I4, I3, I2, I1, I0 };
    wire [5:0] _w_idx_6 = {   I5, I4, I3, I2, I1, I0 };

`ifdef FAST_IQ
    reg O5_f /* verilator public_flat_rw */ = 1'b0;
    reg O5_v /* verilator public_flat_rw */ = 1'b0;
    assign O5 = O5_f ? O5_v : INIT[_w_idx_5];
`else
    assign O5 = INIT[_w_idx_5];
`endif
`ifdef FAST_IQ
    reg O6_f /* verilator public_flat_rw */ = 1'b0;
    reg O6_v /* verilator public_flat_rw */ = 1'b0;
    assign O6 = O6_f ? O6_v : INIT[_w_idx_6];
`else
    assign O6 = INIT[_w_idx_6];
`endif

endmodule
/* verilator coverage_on */
