`timescale  1 ps / 1 ps
//
// SRL16E primitive for Xilinx FPGAs
// Compatible with Verilator tool
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module SRL16E
(
    // Clock
    input  wire CLK,
    // Clock enable
    input  wire CE,
    // Bit output position
    input  wire A0, A1, A2, A3,
    // Data in
    input  wire D,
    // Data out
    output wire Q
);
    parameter [15:0] INIT = 16'h0000;
    
    wire  [3:0] _w_addr = { A3, A2, A1, A0 };
    
    // 16-bit shift register
    reg  [15:0] _r_srl;
    
    // Power-up value
    initial begin
        _r_srl = INIT;
    end
    
    // Shifter logic
    always @(posedge CLK) begin : SHIFTER_16B
    
        if (CE) begin
            _r_srl <= { _r_srl[14:0], D };
        end
    end
    
    // Data out
    assign Q = _r_srl[_w_addr];

endmodule
