`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// MUXF8_D primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module MUXF8_D
(
    input  wire I0, I1,
    input  wire S,
`ifdef FAST_IQ
    output wire LO,
`else
    output wire LO /* verilator public_flat_rd */,
`endif
`ifdef FAST_IQ
    output wire O
`else
    output wire O /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 1;
`endif

`ifdef FAST_IQ
    reg LO_f /* verilator public_flat_rw */ = 1'b0;
    reg LO_v /* verilator public_flat_rw */ = 1'b0;
    assign LO = LO_f ? LO_v : (S) ? I1 : I0;
`else
    assign LO = (S) ? I1 : I0;
`endif
`ifdef FAST_IQ
    reg O_f /* verilator public_flat_rw */ = 1'b0;
    reg O_v /* verilator public_flat_rw */ = 1'b0;
    assign O = O_f ? O_v : (S) ? I1 : I0;
`else
    assign O  = (S) ? I1 : I0;
`endif

endmodule
/* verilator coverage_on */
