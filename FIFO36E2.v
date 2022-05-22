`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif

module FIFO36E2
#(
    // "NONE", "FIRST", "LAST", "MIDDLE", "PARALLEL"
    parameter  [64:1] CASCADE_ORDER           = "NONE",
    // "INDEPENDENT", "COMMON"
    parameter         CLOCK_DOMAINS           = "INDEPENDENT",
    // "FALSE", "TRUE"
    parameter         EN_ECC_PIPE             = "FALSE",
    // "FALSE", "TRUE"
    parameter         EN_ECC_READ             = "FALSE",
    // "FALSE", "TRUE"
    parameter         EN_ECC_WRITE            = "FALSE",
    // "FALSE", "TRUE"
    parameter         FIRST_WORD_FALL_THROUGH = "FALSE",
    // Data registers init value (power-up or GSR)
    parameter  [71:0] INIT                    = 72'h0,
    // Signals polarities
    parameter   [0:0] IS_RSTREG_INVERTED      = 1'b0,
    parameter   [0:0] IS_RST_INVERTED         = 1'b0,
    parameter   [0:0] IS_RDCLK_INVERTED       = 1'b0,
    parameter   [0:0] IS_RDEN_INVERTED        = 1'b0,
    parameter   [0:0] IS_WRCLK_INVERTED       = 1'b0,
    parameter   [0:0] IS_WREN_INVERTED        = 1'b0,
    // Empty threshold
    parameter integer PROG_EMPTY_THRESH       = 256,
    // Full threshold
    parameter integer PROG_FULL_THRESH        = 256,
    // "RAW_PNTR", "EXTENDED_DATACOUNT", "SIMPLE_DATACOUNT", "SYNC_PNTR"
    parameter         RDCOUNT_TYPE            = "RAW_PNTR",
    // 4, 9, 18, 36, 72
    parameter integer READ_WIDTH              = 4,
    // "UNREGISTERED", "DO_PIPELINED", "REGISTERED"
    parameter         REGISTER_MODE           = "UNREGISTERED",
    // "RSTREG", "REGCE"
    parameter         RSTREG_PRIORITY         = "RSTREG",
    // "FALSE", "TRUE" (not used)
    parameter         SLEEP_ASYNC             = "FALSE",
    // Data registers reset value
    parameter  [71:0] SRVAL                   = 72'h0,
    // "RAW_PNTR", "EXTENDED_DATACOUNT", "SIMPLE_DATACOUNT", "SYNC_PNTR"
    parameter         WRCOUNT_TYPE            = "RAW_PNTR",
    // 4, 9, 18, 36, 72
    parameter integer WRITE_WIDTH             = 4
)
(
    // Cascade signals
    input  [63:0] CASDIN,        // Cascade data input
    input   [7:0] CASDINP,       // Cascade parity input
    input         CASDOMUX,      //
    input         CASDOMUXEN,    // NOT USED ?
    output [63:0] CASDOUT,       // Cascade data output
    output  [7:0] CASDOUTP,      // Cascade parity output
    output        CASNXTEMPTY,   // Cascade next empty
    input         CASNXTRDEN,    // Cascade next read enable
    input         CASOREGIMUX,   //
    input         CASOREGIMUXEN, // NOT USED ?
    input         CASPRVEMPTY,   // Cascade previous empty
    output        CASPRVRDEN,    // Cascade previous read enable
    // ECC signals
    input         INJECTDBITERR, // Inject double bit errors
    input         INJECTSBITERR, // Inject single bit error
    output  [7:0] ECCPARITY,
    output        DBITERR,
    output        SBITERR,
    // Reset and power-down
    input         RST,
    input         RSTREG,
    input         SLEEP,
    // Read control signals
    input         RDCLK,
    input         RDEN,
    input         REGCE,
    // Read data
    output [63:0] DOUT,
    output  [7:0] DOUTP,
    // Status
    output        EMPTY,
    output        FULL,
    output        PROGEMPTY,
    output        PROGFULL,
    output [13:0] RDCOUNT,
    output        RDERR,
    output        RDRSTBUSY,
    output [13:0] WRCOUNT,
    output        WRERR,
    output        WRRSTBUSY,
    // Write control signals
    input         WRCLK,
    input         WREN,
    // Write data
    input  [63:0] DIN,
    input   [7:0] DINP
);
    // ========================================================================
    // Local parameters
    // ========================================================================

    localparam [0:0] _CLOCK_DOMAINS   = (CLOCK_DOMAINS == "COMMON" ) ? 1'b1 : 1'b0;
    localparam [0:0] _EN_ECC_PIPE     = (EN_ECC_PIPE   == "TRUE"   ) ? 1'b1 : 1'b0;
    localparam [0:0] _EN_ECC_READ     = (EN_ECC_READ   == "TRUE"   ) ? 1'b1 : 1'b0;
    localparam [0:0] _EN_ECC_WRITE    = (EN_ECC_WRITE  == "TRUE"   ) ? 1'b1 : 1'b0;
    localparam [0:0] _RSTREG_PRIORITY = (RSTREG_PRIORITY == "REGCE") ? 1'b1 : 1'b0;
    localparam [0:0] _FWFT_MODE       = (FIRST_WORD_FALL_THROUGH == "TRUE") ? 1'b1 : 1'b0;


    localparam [4:0] _CASCADE_ORDER   = (CASCADE_ORDER == "PARALLEL") ? 5'b10001
                                      : (CASCADE_ORDER == "FIRST"   ) ? 5'b00010
                                      : (CASCADE_ORDER == "MIDDLE"  ) ? 5'b00100
                                      : (CASCADE_ORDER == "LAST"    ) ? 5'b01000
                                      : 5'b00000;

    localparam [1:0] _REGISTER_MODE   = (REGISTER_MODE == "UNREGISTERED") ? 2'b00
                                      : (REGISTER_MODE == "DO_PIPELINED") ? 2'b01
                                      : (REGISTER_MODE == "REGISTERED"  ) ? 2'b10
                                      : 2'b00;

    localparam [2:0] _RDCOUNT_TYPE    = (RDCOUNT_TYPE == "SYNC_PNTR"         ) ? 3'b001
                                      : (RDCOUNT_TYPE == "SIMPLE_DATACOUNT"  ) ? 3'b010
                                      : (RDCOUNT_TYPE == "EXTENDED_DATACOUNT") ? 3'b100
                                      : 3'b000;

    localparam [2:0] _WRCOUNT_TYPE    = (WRCOUNT_TYPE == "SYNC_PNTR"         ) ? 3'b001
                                      : (WRCOUNT_TYPE == "SIMPLE_DATACOUNT"  ) ? 3'b010
                                      : (WRCOUNT_TYPE == "EXTENDED_DATACOUNT") ? 3'b100
                                      : 3'b000;
    // FIFO read address increment
    localparam [14:0] _RD_ADDR_INC    = (READ_WIDTH ==  4) ? 15'd4
                                      : (READ_WIDTH ==  9) ? 15'd8
                                      : (READ_WIDTH == 18) ? 15'd16
                                      : (READ_WIDTH == 36) ? 15'd32
                                      : (READ_WIDTH == 72) ? 15'd64
                                      : 15'd4;
    // FIFO write address increment
    localparam [14:0] _WR_ADDR_INC    = (WRITE_WIDTH ==  4) ? 15'd4
                                      : (WRITE_WIDTH ==  9) ? 15'd8
                                      : (WRITE_WIDTH == 18) ? 15'd16
                                      : (WRITE_WIDTH == 36) ? 15'd32
                                      : (WRITE_WIDTH == 72) ? 15'd64
                                      : 15'd4;
    // Init value, ECC part (power-up or GSR = 1)
    localparam  [7:0] _INITP          = (READ_WIDTH <= 9)  ? {8{INIT[    8]}}
                                      : (READ_WIDTH == 18) ? {4{INIT[17:16]}}
                                      : (READ_WIDTH == 36) ? {2{INIT[35:32]}}
                                      :                      {1{INIT[71:64]}};
    // Init value, Data part (power-up or GSR = 1)
    localparam [63:0] _INIT           = (READ_WIDTH <= 9)  ? {8{INIT[ 7: 0]}}
                                      : (READ_WIDTH == 18) ? {4{INIT[15: 0]}}
                                      : (READ_WIDTH == 36) ? {2{INIT[31: 0]}}
                                      :                      {1{INIT{63: 0]}};
    // Reset value, ECC part (RST = 1)
    localparam  [7:0] _SRVALP         = (READ_WIDTH <= 9)  ? {8{SRVAL[    8]}}
                                      : (READ_WIDTH == 18) ? {4{SRVAL[17:16]}}
                                      : (READ_WIDTH == 36) ? {2{SRVAL[35:32]}}
                                      :                      {1{SRVAL[71:64]}};
    // Reset value, Data part (RST = 1)
    localparam [63:0] _SRVAL          = (READ_WIDTH <= 9)  ? {8{SRVAL[ 7: 0]}}
                                      : (READ_WIDTH == 18) ? {4{SRVAL[15: 0]}}
                                      : (READ_WIDTH == 36) ? {2{SRVAL[31: 0]}}
                                      :                      {1{SRVAL[63: 0]}};

    // ========================================================================
    // ECC computation functions
    // ========================================================================

    function [7:0] fn_ecc
    (
        input        encode,
        input [63:0] d_i,
        input  [7:0] dp_i
    );
    begin
        //                                                [6]                             [5]             [4]     [3] [2]
        fn_ecc[0] = ^{ dp_i[0] & ~encode, d_i & 64'b1010101_1010101010101010101010101010101_101010101010101_1010101_101_1 };
        fn_ecc[1] = ^{ dp_i[1] & ~encode, d_i & 64'b1100110_1100110011001100110011001100110_110011001100110_1100110_110_1 };
        fn_ecc[2] = ^{ dp_i[2] & ~encode, d_i & 64'b1111000_1111000011110000111100001111000_111100001111000_1111000_111_0 };
        fn_ecc[3] = ^{ dp_i[3] & ~encode, d_i & 64'b0000000_1111111100000000111111110000000_111111110000000_1111111_000_0 };
        fn_ecc[4] = ^{ dp_i[4] & ~encode, d_i & 64'b0000000_1111111111111111000000000000000_111111111111111_0000000_000_0 };
        fn_ecc[5] = ^{ dp_i[5] & ~encode, d_i & 64'b0000000_1111111111111111111111111111111_000000000000000_0000000_000_0 };
        fn_ecc[6] = ^{ dp_i[6] & ~encode, d_i & 64'b1111111_0000000000000000000000000000000_000000000000000_0000000_000_0 };
        fn_ecc[7] = (encode) ? ^{ fn_ecc[6:0], d_i } : ^{ dp_i[6:0], d_i };
    end
    endfunction

    function [71:0] fn_cor_bit
    (
        input  [6:0] error_bit,
        input [63:0] d_i,
        input  [7:0] dp_i
    );
    reg [71:0] _d;
    begin
        _d = { d_i[63:57], dp_i[6], d_i[56:26], dp_i[5], d_i[25:11], dp_i[4],
               d_i[10:4], dp_i[3], d_i[3:1], dp_i[2], d_i[0], dp_i[1:0], dp_i[7] };
        _d[error_bit] = ~_d[error_bit];
        fn_cor_bit = { _d[0], _d[64], _d[32], _d[16], _d[8], _d[4], _d[2], _d[1],
                       _d[71:65], _d[63:33], _d[31:17], _d[15:9], _d[7:5], _d[3] };
    end
    endfunction

    // ========================================================================
    // Global Set / Reset (GSR)
    // ========================================================================

    `ifdef TOP_LEVEL
    wire        _w_GSR = `TOP_LEVEL.GSR;
    `else
    wire        _w_GSR = 1'b0;
    `endif /* TOP_LEVEL */

    // ========================================================================
    // Read and Write clocks
    // ========================================================================

    wire        _w_RDCLK /* verilator clocker */;
    wire        _w_WRCLK /* verilator clocker */;

    assign _w_RDCLK = (IS_RDCLK_INVERTED[0]) ? ~RDCLK : RDCLK;
    assign _w_WRCLK = (IS_WRCLK_INVERTED[0]) ? ~WRCLK : WRCLK;

    // ========================================================================
    // Read and Write resets
    // ========================================================================

    wire        _w_RST    = RST ^ IS_RST_INVERTED[0];
    wire        _w_RSTREG = (!_REGISTER_MODE[0]) ? _w_RDRST
                          : (!_RSTREG_PRIORITY) ? RSTREG ^ IS_RSTREG_INVERTED[0]
                          : (RSTREG ^ IS_RSTREG_INVERTED[0]) & REGCE;

    reg         _r_WRRST;
    reg   [1:0] _r_WRRST_busy;
    reg   [2:0] _r_WRRST_done;

    wire        _w_RDRST;
    reg   [1:0] _r_RDRST_cdc;
    reg   [2:0] _r_RDRST_busy;
    reg   [2:0] _r_RDRST_done;

    always @ (posedge _w_WRCLK) begin : P_WR_RESET

        if (_w_RST & ~WRRSTBUSY) begin
            _r_WRRST <= 1'b1;
        end
        else begin
            // (CLOCK_DOMAINS == "COMMON")
            if (_CLOCK_DOMAINS) begin
                if (_r_WRRST) _r_WRRST <= 1'b0;
            end
            // (CLOCK_DOMAINS == "INDEPENDENT")
            else begin
                if (_r_WRRST_done[2]) _r_WRRST <= 1'b0;
            end
        end
    end

generate
    // (CLOCK_DOMAINS == "COMMON")
    if (_CLOCK_DOMAINS) begin
        // CDC mechanisms disabled
        initial begin
            _r_RDRST_cdc  = 2'b00;
            _r_RDRST_busy = 3'b000;
            _r_RDRST_done = 3'b000;
            _r_WRRST_busy = 2'b00;
            _r_WRRST_done = 3'b000;
        end

        assign _w_RDRST  = _r_WRRST;
        assign RDRSTBUSY = _r_WRRST;
        assign WRRSTBUSY = _r_WRRST;

    end
    // (CLOCK_DOMAINS == "INDEPENDENT")
    else begin
        // RDRST_cdc : WRCLK to RDCLK domain crossing
        always @ (posedge _w_RDCLK) begin : P_RD_RESET_CDC

            if (_w_GSR) begin
                _r_RDRST_cdc <= 2'b00;
            end
            else begin
                _r_RDRST_cdc <= { _r_RDRST_cdc[0], _r_WRRST };
            end
        end
        // RDRST_done : (2 + 3) x RDCLK cycles after WRRST
        always @ (posedge _w_RDCLK) begin : P_RD_RESET_DONE

            if (_w_GSR | ~_r_RDRST_cdc[1]) begin
                _r_RDRST_done <= 3'b000;
            end
            else begin
                _r_RDRST_done <= { _r_RDRST_done[1:0], _r_RDRST_cdc[1] };
            end
        end
        // RDRST_busy : 5 x RDCLK cycles after WRRST
        always @ (posedge _w_RDCLK) begin : P_RD_RESET_BUSY

            if (_w_GSR) begin
                _r_RDRST_busy <= 3'b000;
            end
            else begin
                _r_RDRST_busy <= { _r_RDRST_busy[1:0], _r_RDRST_cdc[1] };
            end
        end
        // WRRST_done : 3 x WRCLK cycles after RDRST_done
        always @ (posedge _w_WRCLK) begin : P_WR_RESET_DONE

            if (_w_GSR | _r_WRRST_done[2]) begin
                _r_WRRST_done <= 3'b000;
            end
            else if (_r_WRRST) begin
                _r_WRRST_done <= { _r_WRRST_done[1:0], _r_RDRST_done[2] };
            end
        end
        // WRRST_busy : 5 x RDCLK + 2 x WRCLK cycles after WRRST
        always @ (posedge _w_WRCLK) begin : P_WR_RESET_BUSY

            if (_w_GSR) begin
                _r_WRRST_busy <= 2'b00;
            end
            else begin
                _r_WRRST_busy <= { _r_WRRST_busy[0], _r_RDRST_busy[2] };
            end
        end

        assign _w_RDRST  = _r_RDRST_cdc[1];
        assign RDRSTBUSY = _r_RDRST_cdc[1];
        assign WRRSTBUSY = _r_WRRST | _r_WRRST_busy[1];

    end
endgenerate

    // ========================================================================
    // Sleep mode
    // ========================================================================

    // Clock domain crossing
    reg   [1:0] _r_SLEEP_RD; // to read clock
    wire        _w_SLEEP_RD;

    reg   [1:0] _r_SLEEP_WR; // to write clock
    wire        _w_SLEEP_WR;

    always @ (posedge _w_GSR or posedge _w_RDCLK) begin : P_SLEEP_RD_CLK

        if (_w_GSR) begin
            _r_SLEEP_RD <= 2'b0;
        end
        else begin
            _r_SLEEP_RD <= { _r_SLEEP_RD[0], SLEEP };
        end
    end

    assign _w_SLEEP_RD = |{ _r_SLEEP_RD, SLEEP };

    always @ (posedge _w_GSR or posedge _w_WRCLK) begin : P_SLEEP_WR_CLK

        if (_w_GSR) begin
            _r_SLEEP_WR <= 2'b0;
        end
        else begin
            _r_SLEEP_WR <= { _r_SLEEP_WR[0], SLEEP };
        end
    end

    assign _w_SLEEP_WR = |{ _r_SLEEP_WR, SLEEP };

    // ========================================================================
    // FIFO cascading
    // ========================================================================

    wire        _w_RDEN = (|_CASCADE_ORDER[2:1])              // FIRST or MIDDLE
                        ? CASNXTRDEN & ~_w_SLEEP_RD           // Cascading mode
                        : RDEN ^ IS_RDEN_INVERTED[0];         // Regular mode

    wire        _w_WREN = (|_CASCADE_ORDER[3:2])              // MIDDLE or LAST
                        ? ~(CASPRVEMPTY | FULL | _w_SLEEP_WR) // Cascading mode
                        : WREN ^ IS_WREN_INVERTED[0];         // Regular mode

    wire  [7:0] _w_DINP = (|_CASCADE_ORDER[3:2])              // MIDDLE or LAST
                        ? CASDINP                             // Cascading mode
                        : DINP;                               // Regular mode

    wire [63:0] _w_DIN  = (|_CASCADE_ORDER[3:2])              // MIDDLE or LAST
                        ? CASDIN                              // Cascading mode
                        : DIN;                                // Regular mode

    assign CASDOUT      = (|_CASCADE_ORDER[2:0])              // PARALLEL, FIRST or MIDDLE
                        ? DOUT                                // Cascading mode
                        : 64'b0;                              // Regular mode

    assign CASDOUTP     = (|_CASCADE_ORDER[2:0])              // PARALLEL, FIRST or MIDDLE
                        ? DOUTP                               // Cascading mode
                        : 8'b0;                               // Regular mode

    assign CASNXTEMPTY  = (|_CASCADE_ORDER[2:1])              // FIRST or MIDDLE
                        ? EMPTY | _w_SLEEP_RD                 // Cascading mode
                        : 1'b0;                               // Regular mode

    assign CASPRVRDEN   = (|_CASCADE_ORDER[3:2])              // MIDDLE or LAST
                        ? ~(CASPRVEMPTY | FULL | _w_SLEEP_WR) // Cascading mode
                        : 1'b0;                               // Regular mode

    reg         _r_CASDOMUX;
    reg         _r_CASOREGIMUX;

    initial begin
        _r_CASDOMUX    = 1'b0;
        _r_CASOREGIMUX = 1'b0;
    end

    always @ (posedge _w_RDCLK) begin

        if (_w_GSR) begin
            _r_CASDOMUX    <= 1'b0;
            _r_CASOREGIMUX <= 1'b0;
        end
        else begin
            // LAST, PARALLEL or MIDDLE
            _r_CASDOMUX    <= (|_CASCADE_ORDER[4:2]) ? CASDOMUX    : 1'b0;
            _r_CASOREGIMUX <= (|_CASCADE_ORDER[4:2]) ? CASOREGIMUX : 1'b0;
        end
    end

    // ========================================================================
    // Memory block (512 x 64-bit + 512 x 8-bit)
    // ========================================================================

    /* verilator lint_off MULTIDRIVEN */
    reg   [7:0] _mem_blk_p [0:511]; // Parity bits
    reg  [63:0] _mem_blk   [0:511]; // Data bits
    /* verilator lint_on MULTIDRIVEN */

    initial begin : MEM_BLK_INIT
        int i;

        for (i = 0; i < 512; i = i + 1) begin
            _mem_blk_p[i] = 8'h00;
            _mem_blk[i]   = 64'h0000000000000000;
        end
    end

    // ========================================================================
    // FIFO write side
    // ========================================================================

    // FIFO write enable
    wire        _w_wr_ena = _w_WREN & ~FULL & ~WRRSTBUSY;
    // ECC bits
    reg   [7:0] _r_ecc_reg_p1;
    // FIFO write address
    reg  [14:0] _r_wr_addr_p0;
    reg  [14:0] _r_wr_addr_p1;
    // FIFO next write address
    wire [14:0] _w_wr_addr_nxt_p0;
    // Clock domain crossing
    reg  [14:0] _r_rd_addr_cc1;
    reg  [14:0] _r_rd_addr_cc2;
    reg  [14:0] _r_rd_addr_cc3;
    wire [14:0] _w_rd_addr_cc;

    initial begin
        _r_ecc_reg_p1 = 8'h00;
    end

    always @ (posedge _w_WRCLK or posedge _w_GSR) begin : P_FIFO_WRITE
        reg [63:0] _v_data; // Data
        reg  [7:0] _v_ecc;  // ECC data
        reg  [8:0] _v_word; // Word select (0 - 511)
        reg  [5:0] _v_bit;  // Bit select (0 - 63)

        if (_w_GSR) begin
            _r_ecc_reg_p1  <= 8'h00;
            _r_wr_addr_p0  <= 15'd0;
            _r_wr_addr_p1  <= 15'd0;
            _r_rd_addr_cc1 <= 15'd0;
            _r_rd_addr_cc2 <= 15'd0;
            _r_rd_addr_cc3 <= 15'd0;
        end
        else if (WRRSTBUSY) begin
            _r_wr_addr_p0  <= 15'd0;
            _r_wr_addr_p1  <= 15'd0;
            _r_rd_addr_cc1 <= 15'd0;
            _r_rd_addr_cc2 <= 15'd0;
            _r_rd_addr_cc3 <= 15'd0;
        end
        else begin
            if (_w_wr_ena) begin
                if (_w_SLEEP_WR) begin
                    $display("Error: WRITE on port B attempted while in SLEEP mode");
                    _r_ecc_reg_p1 <= 8'h00;
                end
                else begin
                    // ECC management
                    if (_EN_ECC_WRITE) begin
                        // Errors injections
                        if (INJECTDBITERR) begin
                            _v_data = _w_DIN ^ 64'h4000000040000000;
                        end
                        else if (INJECTSBITERR) begin
                            _v_data = _w_DIN ^ 64'h0000000040000000;
                        end
                        else begin
                            _v_data = _w_DIN;
                        end
                        _v_ecc         = fn_ecc(1'b1, _w_DIN, _w_DINP);
                        _r_ecc_reg_p1 <= _v_ecc;
                    end
                    else begin
                        _v_data        = _w_DIN;
                        _v_ecc         = _w_DINP;
                        _r_ecc_reg_p1 <= 8'h00;
                    end
                    // Write to memory
                    _v_word = _r_wr_addr_p0[14:6];
                    _v_bit  = _r_wr_addr_p0[5:0];
                    if (WRITE_WIDTH == 4) begin
                        // 4-bit write port
                        _mem_blk  [_v_word][_v_bit+:4]      <= _v_data[3:0];
                    end
                    else if (WRITE_WIDTH == 9) begin
                        // 9-bit write port
                        _mem_blk_p[_v_word][_v_bit[5:3]]    <= _v_ecc[0];
                        _mem_blk  [_v_word][_v_bit+:8]      <= _v_data[7:0];
                    end
                    else if (WRITE_WIDTH == 18) begin
                        // 18-bit write port
                        _mem_blk_p[_v_word][_v_bit[5:3]+:2] <= _v_ecc[1:0];
                        _mem_blk  [_v_word][_v_bit+:16]     <= _v_data[15:0];
                    end
                    else if (WRITE_WIDTH == 36) begin
                        // 36-bit write port
                        _mem_blk_p[_v_word][_v_bit[5:3]+:4] <= _v_ecc[3:0];
                        _mem_blk  [_v_word][_v_bit+:32]     <= _v_data[31:0];
                    end
                    else if (WRITE_WIDTH == 72) begin
                        // 72-bit write port
                        _mem_blk_p[_v_word]                 <= _v_ecc;
                        _mem_blk  [_v_word]                 <= _v_data;
                    end
                end
            end
            // Address managament
            _r_wr_addr_p0 <= _w_wr_addr_nxt_p0;
            // Clock domain crossing
            if (!_CLOCK_DOMAINS) begin
                // WRCLK => RDCLK
                _r_wr_addr_p1  <= _r_wr_addr_p0;
                // RDCLK => WRCLK
                _r_rd_addr_cc1 <= _r_rd_addr_p1;
                _r_rd_addr_cc2 <= _r_rd_addr_cc1;
                _r_rd_addr_cc3 <= _r_rd_addr_cc2;
            end
        end
    end

    assign _w_wr_addr_nxt_p0 = (_w_wr_ena) ? _r_wr_addr_p0 + _WR_ADDR_INC : _r_wr_addr_p0;

    assign _w_rd_addr_cc     = (_CLOCK_DOMAINS) ? _r_rd_addr_p0 : _r_rd_addr_cc3;

    assign ECCPARITY         = _r_ecc_reg_p1;

    // ========================================================================
    // FIFO read side
    // ========================================================================
    
    // FIFO read enable
    wire        _w_rd_ena = _w_RDEN & (1'b1) & ~_w_RDRST;
    // FIFO read address
    reg  [14:0] _r_rd_addr_p0;
    reg  [14:0] _r_rd_addr_p1;
    // FIFO next read address
    wire [14:0] _w_rd_addr_nxt_p0;
    // Clock domain crossing
    reg  [14:0] _r_wr_addr_cc1;
    reg  [14:0] _r_wr_addr_cc2;
    reg  [14:0] _r_wr_addr_cc3;
    wire [14:0] _w_wr_addr_cc;
    // FIFO read data
    reg   [7:0] _r_rd_ecc_p1;
    reg  [63:0] _r_rd_data_p1;
    // ECC related data
    reg         _r_sbiterr_p1;
    reg         _r_dbiterr_p1;

    initial begin
        _r_rd_ecc_p1  = _INITP;
        _r_rd_data_p1 = _INIT;
        _r_sbiterr_p1 = 1'b0;
        _r_dbiterr_p1 = 1'b0;
    end

    always @ (posedge _w_RDCLK or posedge _w_GSR) begin : P_FIFO_READ_P1
        reg [63:0] _v_data; // Data
        reg  [7:0] _v_ecc;  // ECC data
        reg  [7:0] _v_synd; // ECC syndrome
        reg        _v_sbit; // Single bit error
        reg        _v_dbit; // Double bit error
        reg  [8:0] _v_word; // Word select (0 - 511)
        reg  [5:0] _v_bit;  // Bit select (0 - 63)

        if (_w_GSR) begin
            _r_rd_addr_p0  <= 15'd0;
            _r_rd_addr_p1  <= 15'd0;
            _r_wr_addr_cc1 <= 15'd0;
            _r_wr_addr_cc2 <= 15'd0;
            _r_wr_addr_cc3 <= 15'd0;
            _r_rd_ecc_p1   <= _INITP;
            _r_rd_data_p1  <= _INIT;
            _r_sbiterr_p1  <= 1'b0;
            _r_dbiterr_p1  <= 1'b0;
        end
        else if (_w_RDRST) begin
            _r_rd_addr_p0  <= 15'd0;
            _r_rd_addr_p1  <= 15'd0;
            _r_wr_addr_cc1 <= 15'd0;
            _r_wr_addr_cc2 <= 15'd0;
            _r_wr_addr_cc3 <= 15'd0;
            _r_rd_ecc_p1   <= _SRVALP;
            _r_rd_data_p1  <= _SRVAL;
            _r_sbiterr_p1  <= 1'b0;
            _r_dbiterr_p1  <= 1'b0;
        end
        else begin
            if (_w_rd_ena) begin
                if (_w_SLEEP_RD) begin
                    $display("Error: READ on port A attempted while in SLEEP mode");
                    _r_rd_ecc_p1  <= 8'h00;
                    _r_rd_data_p1 <= 64'hDEADDEAD;
                end
                else begin
                    // Read from memory
                    _v_word = _r_rd_addr_p0[14:6];
                    _v_bit  = _r_rd_addr_p0[5:0];
                    // 4-bit read port
                    if (READ_WIDTH == 4) begin
                        _v_ecc  =   8'b0;
                        _v_data = { 60'b0, _mem_blk  [_v_word][_v_bit+:4] };
                    end
                    // 9-bit read port
                    else if (READ_WIDTH == 9) begin
                        _v_ecc  = { 7'b0,  _mem_blk_p[_v_word][_v_bit[5:3]] };
                        _v_data = { 56'b0, _mem_blk  [_v_word][_v_bit+:8] };
                    end
                    // 18-bit read port
                    else if (READ_WIDTH == 18) begin
                        _v_ecc  = { 6'b0,  _mem_blk_p[_v_word][_v_bit[5:3]+:2] };
                        _v_data = { 48'b0, _mem_blk  [_v_word][_v_bit+:16] };
                    end
                    // 36-bit read port
                    else if (READ_WIDTH == 36) begin
                        _v_ecc  = { 4'b0,  _mem_blk_p[_v_word][_v_bit[5:3]+:4] };
                        _v_data = { 32'b0, _mem_blk  [_v_word][_v_bit+:32] };
                    end
                    // 72-bit read port
                    else if (READ_WIDTH == 72) begin
                        _v_ecc  =          _mem_blk_p[_v_word];
                        _v_data =          _mem_blk  [_v_word];
                    end
                    // ECC correction / detection
                    if (_EN_ECC_READ) begin
                        // ECC syndrome computation
                        _v_synd = fn_ecc(1'b0, _v_data, _v_ecc);
                        _v_sbit = (|_v_synd) &  _v_synd[7];
                        _v_dbit = (|_v_synd) & ~_v_synd[7];
                        if (_v_sbit) begin
                            // Correctable error
                            { _r_rd_ecc_p1, _r_rd_data_p1 } <= fn_cor_bit(_v_synd[6:0], _v_data, _v_ecc);
                        end
                        else begin
                            // Uncorrectable error or no error at all
                            { _r_rd_ecc_p1, _r_rd_data_p1 } <= { _v_ecc, _v_data };
                        end
                        // ECC status
                        _r_sbiterr_p1 <= _v_sbit;
                        _r_dbiterr_p1 <= _v_dbit;
                    end
                    else begin
                        // ECC not activated
                        _r_rd_ecc_p1  <= _v_ecc;
                        _r_rd_data_p1 <= _v_data;
                        _r_sbiterr_p1 <= 1'b0;
                        _r_dbiterr_p1 <= 1'b0;
                    end
                end
            end
            else if (_w_RDEN) begin
                rdcount_en <= 1'b1;
            end
            // Address managament
            _r_rd_addr_p0 <= _w_rd_addr_nxt_p0;
            // Clock domain crossing
            if (!_CLOCK_DOMAINS) begin
                // RDCLK => WRCLK
                _r_rd_addr_p1  <= _r_rd_addr_p0;
                // WRCLK => RDCLK
                _r_wr_addr_cc1 <= _r_wr_addr_p1;
                _r_wr_addr_cc2 <= _r_wr_addr_cc1;
                _r_wr_addr_cc3 <= _r_wr_addr_cc2;
            end
        end
    end

    assign _w_rd_addr_nxt_p0 = (_w_rd_ena) ? _r_rd_addr_p0 + _RD_ADDR_INC : _r_rd_addr_p0;

    assign _w_wr_addr_cc     = (_CLOCK_DOMAINS) ? _r_wr_addr_p0 : _r_wr_addr_cc3;

    // ========================================================================
    // Data pipeline
    // ========================================================================


    // ---- 2nd stage ---------------------------------------------------------

    // FIFO read data
    reg   [7:0] _r_rd_ecc_p2;
    reg  [63:0] _r_rd_data_p2;
    // ECC related data
    reg         _r_sbiterr_p2;
    reg         _r_dbiterr_p2;

    initial begin
        _r_rd_ecc_p2  = _INITP;
        _r_rd_data_p2 = _INIT;
        _r_sbiterr_p2 = 1'b0;
        _r_dbiterr_p2 = 1'b0;
    end

    always @ (posedge _w_RDCLK or posedge _w_GSR) begin : P_DATA_PIPE_P2

        if (_w_GSR) begin
            _r_rd_ecc_p2  <= _INITP;
            _r_rd_data_p2 <= _INIT;
            _r_sbiterr_p2 <= 1'b0;
            _r_dbiterr_p2 <= 1'b0;
        end
        else if (_w_RDRST) begin
            _r_rd_ecc_p2  <= _SRVALP;
            _r_rd_data_p2 <= _SRVAL;
            _r_sbiterr_p2 <= 1'b0;
            _r_dbiterr_p2 <= 1'b0;
        end
        else if (WREN_ecc) begin
            _r_rd_ecc_p2  <= _r_rd_ecc_p1;
            _r_rd_data_p2 <= _r_rd_data_p1;
            _r_sbiterr_p2 <= _r_sbiterr_p1;
            _r_dbiterr_p2 <= _r_dbiterr_p1;
        end
    end

    // ---- 3rd stage ---------------------------------------------------------

    // FIFO read data
    reg   [7:0] _r_rd_ecc_p3;
    reg  [63:0] _r_rd_data_p3;
    // ECC related data
    reg         _r_sbiterr_p3;
    reg         _r_dbiterr_p3;

    initial begin
        _r_rd_ecc_p3  = _INITP;
        _r_rd_data_p3 = _INIT;
        _r_sbiterr_p3 = 1'b0;
        _r_dbiterr_p3 = 1'b0;
    end

    always @ (posedge _w_RDCLK or posedge _w_GSR) begin : P_DATA_PIPE_P3

        if (_w_GSR) begin
            _r_rd_ecc_p3  <= _INITP;
            _r_rd_data_p3 <= _INIT;
        end
        else if (_w_RSTREG) begin
            _r_rd_ecc_p3  <= _SRVALP;
            _r_rd_data_p3 <= _SRVAL;
        end
        else if (REGCE_A_int) begin
            // Cascading mode (MIDDLE, LAST, PARALLEL)
            if (_r_CASOREGIMUX) begin
                _r_rd_ecc_p3  <= CASDINP;
                _r_rd_data_p3 <= CASDIN;
            end
            // Regular mode
            else begin
                _r_rd_ecc_p3  <= (_EN_ECC_PIPE) ? _r_rd_ecc_p2  : _r_rd_ecc_p1;
                _r_rd_data_p3 <= (_EN_ECC_PIPE) ? _r_rd_data_p2 : _r_rd_data_p1;
            end
        end
    end

    assign DOUTP = (_r_CASDOMUX) ? CASDINP
                 : (|_REGISTER_MODE) ? _r_rd_ecc_p3
                 : (_EN_ECC_PIPE) ? _r_rd_ecc_p2
                 : _r_rd_ecc_p1;

    assign DOUT  = (_r_CASDOMUX) ? CASDIN
                 : (|_REGISTER_MODE) ? _r_rd_data_p3
                 : (_EN_ECC_PIPE) ? _r_rd_data_p2
                 : _r_rd_data_p1;

    always @ (posedge _w_RDCLK or posedge _w_GSR) begin : P_ECC_PIPE_P3

        if (_w_GSR) begin
            _r_sbiterr_p3 <= 1'b0;
            _r_dbiterr_p3 <= 1'b0;
        end
        else if (_w_RDRST) begin
            _r_sbiterr_p3 <= 1'b0;
            _r_dbiterr_p3 <= 1'b0;
        end
        else if (REGCE_A_int) begin
            _r_sbiterr_p3 <= (_EN_ECC_PIPE) ? _r_sbiterr_p2 : _r_sbiterr_p1;
            _r_dbiterr_p3 <= (_EN_ECC_PIPE) ? _r_dbiterr_p2 : _r_dbiterr_p1;
        end
    end

    assign SBITERR = (|_REGISTER_MODE) ? _r_sbiterr_p3
                   : (_EN_ECC_PIPE) ? _r_sbiterr_p2
                   : _r_sbiterr_p1;

    assign DBITERR = (|_REGISTER_MODE) ? _r_dbiterr_p3
                   : (_EN_ECC_PIPE) ? _r_dbiterr_p2
                   : _r_dbiterr_p1;

endmodule
