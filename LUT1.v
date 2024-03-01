`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// LUT1 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module LUT1
#(
    parameter [1:0] INIT = 2'b00
)
(
    input  wire I0,
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
    reg O_f /* verilator public_flat_rw */ = 1'b0;
    reg O_v /* verilator public_flat_rw */ = 1'b0;
    assign O = O_f ? O_v : INIT[I0];
`else
    assign O = INIT[I0];
`endif

endmodule
/* verilator coverage_on */
