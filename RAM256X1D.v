`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif
//
// RAM256X1D primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
//

module RAM256X1D
#(
    parameter [255:0] INIT = 256'h0
)
(
    // Write clock
    input  wire       WCLK,
    // Write enable
    input  wire       WE,
    // Read / Write address
    input  wire [7:0] A,
    // Read address
    input  wire [7:0] DPRA,
    // Data in
    input  wire       D,
    // Data out
    output wire       SPO,
    output wire       DPO
);
    // 256 x 1-bit Select RAM
    reg  [255:0] _r_mem;
    
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
    assign SPO = _r_mem[A];
    assign DPO = _r_mem[DPRA];

endmodule
