`timescale  1 ps / 1 ps
//
// RAM128X1S primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module RAM128X1S
#(
    parameter [127:0] INIT = 128'h0
)
(
    // Write clock
    input  wire       WCLK,
    // Write enable
    input  wire       WE,
    // Read / Write address
    input  wire [6:0] A,
    // Data in
    input  wire       D,
    // Data out
    output wire       O
);
    // 128 x 1-bit Select RAM
    reg  [127:0] _r_mem;
    
    // Power-up value
    initial begin : INIT_STATE
        _r_mem = INIT;
    end
    
    // Synchronous memory write
    always @(posedge WCLK) begin : MEM_WRITE
    
        if (WE) begin
            _r_mem[A] <= D;
        end
    end
    
    // Asynchronous memory read
    assign O = _r_mem[A];

endmodule
