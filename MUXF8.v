`timescale  1 ps / 1 ps
//
// MUXF8 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module MUXF8
(
    input  wire I0, I1,
    input  wire S,
    output wire O
);

    assign O = (S) ? I1 : I0;

endmodule
