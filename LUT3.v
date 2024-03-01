`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// LUT3 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module LUT3
#(
    parameter [7:0] INIT = 8'b00000000
)
(
    input  wire I0, I1, I2,
`ifdef FAST_IQ
    output wire O
`else
    output wire O /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 1;
`endif
    wire [2:0] _w_idx = { I2, I1, I0 };

`ifdef FAST_IQ
    reg O_f /* verilator public_flat_rw */ = 1'b0;
    reg O_v /* verilator public_flat_rw */ = 1'b0;
    assign O = O_f ? O_v : INIT[_w_idx];
`else
    assign O = INIT[_w_idx];
`endif

endmodule
/* verilator coverage_on */
