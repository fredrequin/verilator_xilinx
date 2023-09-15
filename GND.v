`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// GND primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module GND
(
    output wire G
);

    assign G = 1'b0;

endmodule
/* verilator coverage_on */
