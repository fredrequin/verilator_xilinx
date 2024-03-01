`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// LUT5_D primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module LUT5_D
#(
    parameter [31:0] INIT = 32'h00000000
)
(
    input  wire I0, I1, I2, I3, I4,
`ifdef FAST_IQ
    output wire LO,
`else
    output wire LO /* verilator public_flat_rd */,
`endif
`ifdef FAST_IQ
    output wire O
`else
    output wire O /* verilator public_flat_rd */
`endif
);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 1;
`endif

    wire [4:0] _w_idx = { I4, I3, I2, I1, I0 };

`ifdef FAST_IQ
    reg LO_f /* verilator public_flat_rw */ = 1'b0;
    reg LO_v /* verilator public_flat_rw */ = 1'b0;
    assign LO = LO_f ? LO_v : INIT[_w_idx];
`else
    assign LO = INIT[_w_idx];
`endif
`ifdef FAST_IQ
    reg O_f /* verilator public_flat_rw */ = 1'b0;
    reg O_v /* verilator public_flat_rw */ = 1'b0;
    assign O = O_f ? O_v : INIT[_w_idx];
`else
    assign O  = INIT[_w_idx];
`endif

endmodule
/* verilator coverage_on */
