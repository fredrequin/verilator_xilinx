`timescale  1 ps / 1 ps
//
// VCC primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module VCC
(
    output wire P
);

    assign P = 1'b1;

endmodule
