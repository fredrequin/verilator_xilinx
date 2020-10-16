`timescale  1 ps / 1 ps
//
// RAM64M primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2020 Frédéric REQUIN
// License : BSD
//

module RAM64M
#(
    parameter  [63:0] INIT_A           = 64'h0,
    parameter  [63:0] INIT_B           = 64'h0,
    parameter  [63:0] INIT_C           = 64'h0,
    parameter  [63:0] INIT_D           = 64'h0,
    parameter   [0:0] IS_WCLK_INVERTED = 1'b0
)
(
    // Write clock
    input  wire       WCLK,
    // Write enable
    input  wire       WE,
    // Port A
    input  wire [5:0] ADDRA,
    input  wire       DIA,
    output wire       DOA,
    // Port B
    input  wire [5:0] ADDRB,
    input  wire       DIB,
    output wire       DOB,
    // Port C
    input  wire [5:0] ADDRC,
    input  wire       DIC,
    output wire       DOC,
    // Port D
    input  wire [5:0] ADDRD,
    input  wire       DID,
    output wire       DOD
);
    // 64 x 4-bit Select RAM
    reg  [63:0] _r_mem_a;
    reg  [63:0] _r_mem_b;
    reg  [63:0] _r_mem_c;
    reg  [63:0] _r_mem_d;
    
    // Power-up value
    initial begin : INIT_STATE
        _r_mem_a = INIT_A;
        _r_mem_b = INIT_B;
        _r_mem_c = INIT_C;
        _r_mem_d = INIT_D;
    end
    
    // Synchronous memory write
    always @(posedge WCLK) begin : MEM_WRITE
    
        if (WE) begin
            _r_mem_a[ADDRA] <= DIA;
            _r_mem_b[ADDRB] <= DIB;
            _r_mem_c[ADDRC] <= DIC;
            _r_mem_d[ADDRD] <= DID;
        end
    end
    
    // Asynchronous memory read
    assign DOA = _r_mem_a[ADDRA];
    assign DOB = _r_mem_b[ADDRB];
    assign DOC = _r_mem_c[ADDRC];
    assign DOD = _r_mem_d[ADDRD];

endmodule
