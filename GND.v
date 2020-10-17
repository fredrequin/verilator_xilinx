`timescale  1 ps / 1 ps
//
// GND primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module GND
(
    output wire G
);

    assign G = 1'b0;

endmodule
