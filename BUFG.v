`timescale 1 ps / 1 ps
//
// BUFG primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

module BUFG
(
    input  I,
    output O /* verilator clocker */
);

    assign O = I;

endmodule
