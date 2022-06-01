`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// MUXF8_L primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

module MUXF8_L
(
    input  wire I0, I1,
    input  wire S,
    output wire LO
);

    assign LO = (S) ? I1 : I0;

endmodule
