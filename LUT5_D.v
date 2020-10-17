`timescale  1 ps / 1 ps
//
// LUT5_D primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module LUT5_D
#(
    parameter [31:0] INIT = 32'h00000000
)
(
    input  wire I0, I1, I2, I3, I4,
    output wire LO,
    output wire O
);
    
    wire [4:0] _w_idx = { I4, I3, I2, I1, I0 };
    
    assign LO = INIT[_w_idx];
    assign O  = INIT[_w_idx];

endmodule
