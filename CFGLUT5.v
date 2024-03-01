`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// CFGLUT5 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

/* verilator coverage_off */
module CFGLUT5
#(
    parameter [31:0] INIT            = 32'h00000000,
    parameter  [0:0] IS_CLK_INVERTED = 1'b0
)
(
    // Clock
    input  wire CLK,
    // Clock enable
    input  wire CE,
    // LUT inputs
    input  wire I0, I1, I2, I3, I4,
    // LUT configuration data input
    input  wire CDI,
    // LUT configuration data output
`ifdef FAST_IQ
    output wire CDO,
`else
    output wire CDO /* verilator public_flat_rd */,
`endif
    // LUT4 output
`ifdef FAST_IQ
    output wire O5,
`else`
    output wire O5 /* verilator public_flat_rd */,
`endif
    // LUT5 output
`ifdef FAST_IQ
    output wire O6
`else
    output wire O6 /* verilator public_flat_rd */
`endif

);
`ifdef SCOPE_IQ
    localparam cell_kind /* verilator public_flat_rd */ = 1;
`endif
    reg [31:0] _r_sreg;

    initial begin : INIT_STATE
        _r_sreg = INIT;
    end

    generate
        if (IS_CLK_INVERTED) begin : GEN_CLK_NEG
            always @(negedge CLK) begin

                if (CE) begin
                    _r_sreg <= { _r_sreg[30:0], CDI };
                end
            end
        end
        else begin : GEN_CLK_POS
            always @(posedge CLK) begin

                if (CE) begin
                    _r_sreg <= { _r_sreg[30:0], CDI };
                end
            end
        end
    endgenerate

`ifdef FAST_IQ
    reg O6_f /* verilator public_flat_rw */ = 1'b0;
    reg O6_v /* verilator public_flat_rw */ = 1'b0;
    assign O6 = O6_f ? O6_v : _r_sreg[{   I4, I3, I2, I1, I0 }];
    reg O5_f /* verilator public_flat_rw */ = 1'b0;
    reg O5_v /* verilator public_flat_rw */ = 1'b0;
    assign O5 = O5_f ? O5_v : _r_sreg[{ 1'b0, I3, I2, I1, I0 }];
    reg CDO_f /* verilator public_flat_rw */ = 1'b0;
    reg CDO_v /* verilator public_flat_rw */ = 1'b0;
    assign CDO = CDO_f ? CDO_v : _r_sreg[31];
`else
    assign O6  = _r_sreg[{   I4, I3, I2, I1, I0 }];
    assign O5  = _r_sreg[{ 1'b0, I3, I2, I1, I0 }];
    assign CDO = _r_sreg[31];
`endif

endmodule
/* verilator coverage_on */
