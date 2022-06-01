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

module MUXF8_D
(
    input  wire I0, I1,
    input  wire S,
    output wire LO,
    output wire O
);

    assign LO = (S) ? I1 : I0;
    assign O  = (S) ? I1 : I0;

endmodule
