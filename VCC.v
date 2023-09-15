`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// VCC primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module VCC
(
    output wire P
);

    assign P = 1'b1;

endmodule
/* verilator coverage_on */
