`ifdef verilator3
`else
`timescale 1 ps / 1 ps
`endif

/* verilator coverage_off */
module DSP48E2
#(
    parameter integer AREG                      = 1,
    parameter integer BREG                      = 1,
    parameter integer CREG                      = 1,
    parameter integer DREG                      = 1,
    parameter integer MREG                      = 1,
    parameter integer PREG                      = 1,
    parameter integer ADREG                     = 1,
    parameter integer ACASCREG                  = 1,
    parameter integer BCASCREG                  = 1,
    parameter integer CARRYINREG                = 1,
    parameter integer INMODEREG                 = 1,
    parameter integer OPMODEREG                 = 1,
    parameter integer ALUMODEREG                = 1,
    parameter integer CARRYINSELREG             = 1,
    parameter string  AUTORESET_PATDET          = "NO_RESET",
    parameter string  AUTORESET_PRIORITY        = "RESET",
    parameter string  A_INPUT                   = "DIRECT",      // "DIRECT" or "CASCADE"
    parameter string  B_INPUT                   = "DIRECT",      // "DIRECT" or "CASCADE"
    parameter string  AMULTSEL                  = "A",           // "A" or "AD"
    parameter string  BMULTSEL                  = "B",           // "B" or "AD"
    parameter string  PREADDINSEL               = "A",           // "A" or "B"
    parameter string  SEL_MASK                  = "MASK",        // "MASK", "C", "ROUNDING_MODE1" or "ROUNDING_MODE2"
    parameter string  SEL_PATTERN               = "PATTERN",     // "PATTERN" or "C"
    parameter string  USE_MULT                  = "MULTIPLY",    // "MULTIPLY", "DYNAMIC" or "NONE"
    parameter string  USE_SIMD                  = "ONE48",       // "ONE48", "TWO24" or "FOUR12"
    parameter string  USE_PATTERN_DETECT        = "NO_PATDET",   // "NO_PATDET" or "PATDET"
    parameter string  USE_WIDEXOR               = "FALSE",       // "FALSE" or "TRUE"
    parameter string  XORSIMD                   = "XOR24_48_96", // "XOR24_48_96" or "XOR12"
    parameter   [3:0] IS_ALUMODE_INVERTED       = 4'b0000,
    parameter   [0:0] IS_CARRYIN_INVERTED       = 1'b0,
    parameter   [0:0] IS_CLK_INVERTED           = 1'b0,
    parameter   [4:0] IS_INMODE_INVERTED        = 5'b00000,
    parameter   [8:0] IS_OPMODE_INVERTED        = 9'b000000000,
    parameter   [0:0] IS_RSTA_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTB_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTC_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTD_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTM_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTP_INVERTED          = 1'b0,
    parameter   [0:0] IS_RSTCTRL_INVERTED       = 1'b0,
    parameter   [0:0] IS_RSTINMODE_INVERTED     = 1'b0,
    parameter   [0:0] IS_RSTALUMODE_INVERTED    = 1'b0,
    parameter   [0:0] IS_RSTALLCARRYIN_INVERTED = 1'b0,
    parameter  [47:0] MASK                      = 48'h3FFFFFFFFFFF,
    parameter  [47:0] PATTERN                   = 48'h000000000000,
    parameter  [47:0] RND                       = 48'h000000000000
)
(
    input  wire        CLK,
    // A input (with cascading I/Os)
    input  wire        RSTA,
    input  wire        CEA1,
    input  wire        CEA2,
    input  wire [29:0] A,
    input  wire [29:0] ACIN,
    output wire [29:0] ACOUT,
    // B input (with cascading I/Os)
    input  wire        RSTB,
    input  wire        CEB1,
    input  wire        CEB2,
    input  wire [17:0] B,
    input  wire [17:0] BCIN,
    output wire [17:0] BCOUT,
    // C input
    input  wire        RSTC,
    input  wire        CEC,
    input  wire [47:0] C,
    // D input
    input  wire        RSTD,
    input  wire        CED,
    input  wire        CEAD,
    input  wire [26:0] D,
    // Multiplier
    input  wire        RSTM,
    input  wire        CEM,
    // Control inputs
    input  wire        RSTINMODE,
    input  wire        CEINMODE,
    input  wire  [4:0] INMODE,
    input  wire        RSTCTRL,
    input  wire        CECTRL,
    input  wire  [8:0] OPMODE,
    input  wire  [2:0] CARRYINSEL,
    input  wire        RSTALUMODE,
    input  wire        CEALUMODE,
    input  wire  [3:0] ALUMODE,
    // ALU
    input  wire        RSTP,
    input  wire        RSTALLCARRYIN,
    input  wire        CEP,
    input  wire        CECARRYIN,
    input  wire        MULTSIGNIN,
    input  wire        CARRYCASCIN,
    input  wire        CARRYIN,
    input  wire [47:0] PCIN,
    output wire        MULTSIGNOUT,
    output wire        CARRYCASCOUT,
    output wire  [3:0] CARRYOUT,
    output wire [47:0] PCOUT,
    output wire [47:0] P,
    output wire  [7:0] XOROUT,
    // Flags
    output wire        OVERFLOW,
    output wire        UNDERFLOW,
    output wire        PATTERNDETECT,
    output wire        PATTERNBDETECT
);
    localparam  [0:0] c_DREG  = ((AMULTSEL == "A") && (BMULTSEL == "B") ||
                                (USE_MULT == "NONE")) ? 1'b0 : DREG[0];
    localparam  [0:0] c_ADREG = ((AMULTSEL == "A") && (BMULTSEL == "B") ||
                                (USE_MULT == "NONE")) ? 1'b0 : ADREG[0];
    localparam [43:0] c_UMASK = 44'h55555555555;
    localparam [43:0] c_VMASK = 44'hAAAAAAAAAAA;
    localparam [47:0] c_CSIMD = (USE_SIMD == "FOUR12") ? 48'hFFF_7FF_7FF_7FF
                              : (USE_SIMD == "TWO24" ) ? 48'hFFF_FFF_7FF_FFF
                              : (USE_SIMD == "ONE48" ) ? 48'hFFF_FFF_FFF_FFF
                              : 48'hFFF_FFF_FFF_FFF;
    
    // ============================== CLOCK and RESETs ==============================

    wire w_CLK        =                  CLK ^ IS_CLK_INVERTED[0];

    wire w_RSTA       = (|AREG[1:0])   ? RSTA ^ IS_RSTA_INVERTED[0] : 1'b1;
    wire w_RSTB       = (|BREG[1:0])   ? RSTB ^ IS_RSTB_INVERTED[0] : 1'b1;
    wire w_RSTC       = (CREG[0])      ? RSTC ^ IS_RSTC_INVERTED[0] : 1'b1;
    wire w_RSTD       = (c_DREG[0])    ? RSTD ^ IS_RSTD_INVERTED[0] : 1'b1;
    wire w_RSTM       = (MREG[0])      ? RSTM ^ IS_RSTM_INVERTED[0] : 1'b1;
    wire w_RSTP       = (PREG[0])      ? RSTP ^ IS_RSTP_INVERTED[0] : 1'b1;

    wire w_RSTCTRL    =                  RSTCTRL ^ IS_RSTCTRL_INVERTED[0];
    wire w_RSTINMODE  = (INMODEREG[0]) ? RSTINMODE ^ IS_RSTINMODE_INVERTED[0] : 1'b1;
    wire w_RSTALUMODE =                  RSTALUMODE ^ IS_RSTALUMODE_INVERTED[0];

    // ============================== ALUMODE input ==============================
    
    wire [3:0] w_ALUMODE_p0 = ALUMODE ^ IS_ALUMODE_INVERTED;
    reg  [3:0] r_ALUMODE_p1;

    always @(posedge w_CLK) begin : ALUMODE_REG

        if (w_RSTALUMODE)
            r_ALUMODE_p1 <= 4'b0;
        else if (CEALUMODE)
            r_ALUMODE_p1 <= w_ALUMODE_p0;
    end
    
    wire [3:0] w_ALUMODE_mux = (ALUMODEREG[0]) ? r_ALUMODE_p1 : w_ALUMODE_p0;
    
    // ============================== INMODE input ==============================
    
    wire [4:0] w_INMODE_p0 = INMODE ^ IS_INMODE_INVERTED;
    reg  [4:0] r_INMODE_p1;

    always @(posedge w_CLK) begin : INMODE_REG

        if (w_RSTINMODE)
            r_INMODE_p1 <= 5'b0;
        else if (CEINMODE)
            r_INMODE_p1 <= w_INMODE_p0;
    end
    
    wire [4:0] w_INMODE_mux = (INMODEREG[0]) ? r_INMODE_p1 : w_INMODE_p0;
    
    // ============================== OPMODE input ==============================
    
    wire [8:0] w_OPMODE_p0 = OPMODE ^ IS_OPMODE_INVERTED;
    reg  [8:0] r_OPMODE_p1;

    always @(posedge w_CLK) begin : OPMODE_REG

        if (w_RSTCTRL)
            r_OPMODE_p1 <= 9'b0;
        else if (CECTRL)
            r_OPMODE_p1 <= w_OPMODE_p0;
    end

    wire [8:0] w_OPMODE_mux = (OPMODEREG[0]) ? r_OPMODE_p1 : w_OPMODE_p0;

    // ============================== CARRYINSEL input ==============================
    
    wire [2:0] w_CARRYINSEL_p0 = CARRYINSEL;
    reg  [2:0] r_CARRYINSEL_p1;

    always @(posedge w_CLK) begin : CARRYINSEL_REG

        if (w_RSTCTRL)
            r_CARRYINSEL_p1 <= 3'b0;
        else if (CECTRL)
            r_CARRYINSEL_p1 <= w_CARRYINSEL_p0;
    end

    wire [2:0] w_CARRYINSEL_mux = (CARRYINSELREG[0]) ? r_CARRYINSEL_p1 : w_CARRYINSEL_p0;

    // ============================== A1 register ==============================
    
    wire [29:0] w_A_p0 = (A_INPUT == "CASCADE") ? ACIN : A;
    reg  [29:0] r_A_p1;

    always @(posedge w_CLK) begin : A1_REG

        if (w_RSTA)
            r_A_p1 <= 30'b0;
        else if (CEA1)
            r_A_p1 <= w_A_p0;
    end

    // ============================== A2 register ==============================

    wire [29:0] w_A_p1 = (AREG[1:0] == 2'b10) ? r_A_p1 : w_A_p0;
    reg  [29:0] r_A_p2;

    always @(posedge w_CLK) begin : A2_REG

        if (w_RSTA)
            r_A_p2 <= 30'b0;
        else if (CEA2)
            r_A_p2 <= w_A_p1;
    end
    
    wire [29:0] w_A_p2 = (AREG[1:0] != 2'b00) ? r_A_p2 : w_A_p0;

    assign ACOUT = (ACASCREG[1:0] == AREG[1:0]) ? w_A_p2 : r_A_p1;

    // ============================== B1 register ==============================
    
    wire [17:0] w_B_p0 = (B_INPUT == "CASCADE") ? BCIN : B;
    reg  [17:0] r_B_p1;

    always @(posedge w_CLK) begin : B1_REG

        if (w_RSTB)
            r_B_p1 <= 18'b0;
        else if (CEB1)
            r_B_p1 <= w_B_p0;
    end

    // ============================== B2 register ==============================
    
    wire [17:0] w_B_p1 = (BREG[1:0] == 2'b10) ? r_B_p1 : w_B_p0;
    reg  [17:0] r_B_p2;

    always @(posedge w_CLK) begin : B2_REG

        if (w_RSTB)
            r_B_p2 <= 18'b0;
        else if (CEB2)
            r_B_p2 <= w_B_p1;
    end
    
    wire [17:0] w_B_p2 = (BREG[1:0] != 2'b00) ? r_B_p2 : w_B_p0;

    assign BCOUT = (BCASCREG[1:0] == BREG[1:0]) ? w_B_p2 : r_B_p1;

    // ============================== C register ==============================

    reg  [47:0] r_C_p1;

    always @(posedge w_CLK) begin : C_REG

        if (w_RSTC)
            r_C_p1 <= 48'b0;
        else if (CEC)
            r_C_p1 <= C;
    end
    
    wire [47:0] w_C_p1 = (CREG[0]) ? r_C_p1 : C;

    // ============================== D register ==============================

    reg  [26:0] r_D_p1;

    always @(posedge w_CLK) begin : D_REG

        if (w_RSTD)
            r_D_p1 <= 27'b0;
        else if (CED)
            r_D_p1 <= D;
    end
    
    wire [26:0] w_D_p1 = (c_DREG[0]) ? r_D_p1 : D;

    // ============================== A2A1, B2B1, AB and D muxes ==============================
    
    wire [26:0] w_A2A1_mux = (PREADDINSEL == "A") && (w_INMODE_mux[1]) ? 27'b0
                           : (w_INMODE_mux[0]) ? r_A_p1[26:0]
                           : w_A_p2[26:0];

    wire [17:0] w_B2B1_mux = (PREADDINSEL == "B") && (w_INMODE_mux[1]) ? 18'b0
                           : (w_INMODE_mux[4]) ? r_B_p1[17:0]
                           : w_B_p2[17:0];

    wire [26:0] w_AB_mux   = (PREADDINSEL == "B")
                           ? { {9{w_B2B1_mux[17]}}, w_B2B1_mux[17:0] }
                           : w_A2A1_mux[26:0];

    wire [26:0] w_D_mux    = (w_INMODE_mux[2]) ? w_D_p1 : 27'b0;

    // ============================== AD register ==============================

    // Pre-adder
    wire [26:0] w_AD_p1 = (w_INMODE_mux[3])
                        ? (w_D_mux - w_AB_mux)
                        : (w_D_mux + w_AB_mux);
    reg  [26:0] r_AD_p2;

    always @(posedge w_CLK) begin : AD_REG

        if (RSTD ^ IS_RSTD_INVERTED[0])
            r_AD_p2 <= 27'b0;
        else if (CEAD)
            r_AD_p2 <= D;
    end

    wire [26:0] w_AD_p2 = (c_ADREG[0]) ? r_AD_p2 : w_AD_p1;

    // ============================== Multiplier ==============================
    
    // Choose between A or AD
    wire signed [44:0] w_AMULT_mux = (AMULTSEL == "A")
                                   ? { {18{w_A2A1_mux[26]}}, w_A2A1_mux[26:0] }
                                   : { {18{w_AD_p2[26]}},    w_AD_p2[26:0] };
    // Choose between B or AD
    wire signed [44:0] w_BMULT_mux = (BMULTSEL == "B")
                                   ? { {27{w_B2B1_mux[17]}}, w_B2B1_mux[17:0] }
                                   : { {27{w_AD_p2[17]}},    w_AD_p2[17:0] };

    wire signed [44:0] w_MULT = w_AMULT_mux * w_BMULT_mux;

    // ============================== U and V registers ==============================
    
    wire [44:0] w_U_p2 = {        1'b1, w_MULT[43:0] & c_UMASK };
    wire [44:0] w_V_p2 = { ~w_MULT[44], w_MULT[43:0] & c_VMASK };
    reg  [44:0] r_U_p3;
    reg  [44:0] r_V_p3;

    always @(posedge w_CLK) begin : UV_REG

        if (w_RSTM) begin
            r_U_p3 <= 45'b0;
            r_V_p3 <= 45'b0;
        end
        else if (CEM) begin
            r_U_p3 <= w_U_p2;
            r_V_p3 <= w_V_p2;
        end
    end

    wire [44:0] w_U_mux = (USE_SIMD != "ONE48")
                        ? 45'h100000000000
                        : (MREG[0]) ? r_U_p3 : w_U_p2;
    wire [44:0] w_V_mux = (USE_SIMD != "ONE48")
                        ? 45'h100000000000
                        : (MREG[0]) ? r_V_p3 : w_V_p2;

    // ============================== W, X, Y and Z muxes ==============================
    
    reg [47:0] r_W_mux;
    reg [47:0] r_X_mux;
    reg [47:0] r_Y_mux;
    reg [47:0] r_Z_mux;
    
    always @(*) begin : WXYZ_MUXES

        // W mux
        case (w_OPMODE_mux[8:7])
            2'b00 : r_W_mux = 48'h000000000000;
            2'b01 : r_W_mux = r_ALUOUT_p4;
            2'b10 : r_W_mux = RND;
            2'b11 : r_W_mux = w_C_p1;
        endcase

        // X mux
        case (w_OPMODE_mux[1:0])
            2'b00 : r_X_mux = (w_OPMODE_mux[6:4] == 3'b100)
                            ? { 46'b0, MULTSIGNIN, 1'b0 } : 48'b0;
            2'b01 : r_X_mux = { {3{w_U_mux[44]}}, w_U_mux };
            2'b10 : r_X_mux = r_ALUOUT_p4;
            2'b11 : r_X_mux = { w_A_p2, w_B_p2 };
        endcase

        // Y mux
        case (w_OPMODE_mux[3:2])
            2'b00 : r_Y_mux = 48'h000000000000;
            2'b01 : r_Y_mux = { 3'b0, w_V_mux };
            2'b10 : r_Y_mux = 48'hFFFFFFFFFFFF;
            2'b11 : r_Y_mux = w_C_p1;
        endcase

        // Z mux
        case (w_OPMODE_mux[6:4])
            3'b000  : r_Z_mux = 48'h000000000000;
            3'b001  : r_Z_mux = PCIN;
            3'b010  : r_Z_mux = r_ALUOUT_p4;
            3'b011  : r_Z_mux = w_C_p1;
            3'b100  : r_Z_mux = r_ALUOUT_p4;
            3'b101  : r_Z_mux = { {17{PCIN[47]}}, PCIN[47:17] };
            default : r_Z_mux = { {17{r_ALUOUT_p4[47]}}, r_ALUOUT_p4[47:17] };
        endcase
    end

    // ============================== CARRY ==============================
    
    wire w_CMULT_p2 = ~(w_AMULT_mux[26] ^ w_BMULT_mux[17]);
    reg  r_CMULT_p3;
    
    always @(posedge w_CLK) begin : CMULT_REG

	    if (RSTALLCARRYIN)
            r_CMULT_p3 <= 1'b0;
	    else if (CEM)
            r_CMULT_p3 <= w_CMULT_p2;
    end
    
    wire w_CMULT_mux = (MREG[0]) ? r_CMULT_p3 : w_CMULT_p2;
    
    reg  r_CARRYIN;
    
    always @(posedge w_CLK) begin : CARRYIN_REG

	    if (RSTALLCARRYIN)
            r_CARRYIN <= 1'b0;
	    else if (CECARRYIN)
            r_CARRYIN <= CARRYIN;
    end
    
    wire w_CARRYIN_mux = (CARRYINREG[0]) ? r_CARRYIN : CARRYIN;

    reg  r_C_in;

    always @(*) begin : CIN_MUX

        if (w_ALUMODE_mux[3:2] != 2'b00) begin
            r_C_in = 1'b0;
        end
        else begin
            case (w_CARRYINSEL_mux)
                3'b000  : r_C_in = w_CARRYIN_mux;
                3'b001  : r_C_in = ~PCIN[47];
                3'b010  : r_C_in = CARRYCASCIN;
                3'b011  : r_C_in = PCIN[47];
                3'b100  : r_C_in = r_ALUMODE10_p4 ^ r_COUT_p4[3];
                3'b101  : r_C_in = ~r_ALUOUT_p4[47];
                3'b110  : r_C_in = w_CMULT_mux;
                3'b111  : r_C_in = r_ALUOUT_p4[47];
            endcase
        end
    end
    
    // ============================== ALU ==============================

    wire [47:0] w_Z_mux  = (w_ALUMODE_mux[0]) ? ~r_Z_mux : r_Z_mux;
    
    wire [47:0] w_C_alu  = r_X_mux & r_Y_mux
                         | w_Z_mux & r_X_mux
                         | w_Z_mux & r_Y_mux;

    wire [47:0] w_S_alu  = r_X_mux ^ r_Y_mux ^ w_Z_mux;

    wire [47:0] w_C_mux  = (w_ALUMODE_mux[2]) ?   48'b0 : w_C_alu;
    wire [47:0] w_S_mux  = (w_ALUMODE_mux[3]) ? w_C_alu : w_S_alu;

    /* verilator lint_off UNUSED */
    wire [48:0] w_C_simd = { w_C_mux & c_CSIMD, 1'b0 };
    /* verilator lint_on UNUSED */
    
    wire [47:0] w_S_add  = w_S_mux ^ r_W_mux ^ w_C_simd[47:0];
    wire [48:0] w_C_add  = { w_S_mux & w_C_simd[47:0]
                           | r_W_mux & w_C_simd[47:0]
                           | w_S_mux & r_W_mux, r_C_in };
    wire [48:0] w_C_addm = w_C_add & { c_CSIMD, 1'b1 };
                           
    wire [12:0] w_sum0;
    wire [12:0] w_sum1;
    wire [12:0] w_sum2;
    wire [13:0] w_sum3;
    wire [12:0] w_cin1;
    wire [12:0] w_cin2;
    wire [13:0] w_cin3;
    wire  [3:0] w_cout;
    wire  [3:0] w_cout_ena = ((w_OPMODE_mux[3:0] == 4'b0101) || (w_ALUMODE_mux[3:2] != 2'b00))
                           ? { 1'b1, ~c_CSIMD[35], ~c_CSIMD[23], ~c_CSIMD[11] } : 4'b0000;
    
    assign w_sum0    = w_C_addm[11:0] + w_S_add[11:0];
    assign w_cout[0] = w_ALUMODE10_p3 ^ w_sum0[12] ^ w_C_add[12] ^ w_C_mux[11];
    
    assign w_cin1    = { 12'b0, w_sum0[12] & c_CSIMD[11] };
    assign w_sum1    = w_C_addm[23:12] + w_S_add[23:12] + w_cin1;
    assign w_cout[1] = w_ALUMODE10_p3 ^ w_sum1[12] ^ w_C_add[24] ^ w_C_mux[23];

    assign w_cin2    = { 12'b0, w_sum1[12] & c_CSIMD[23] };
    assign w_sum2    = w_C_addm[35:24] + w_S_add[35:24] + w_cin2;
    assign w_cout[2] = w_ALUMODE10_p3 ^ w_sum2[12] ^ w_C_add[36] ^ w_C_mux[35];
    
    assign w_cin3    = { 13'b0, w_sum2[12] & c_CSIMD[35] };
    assign w_sum3    = w_C_addm[48:36] + { w_S_add[47], w_S_add[47:36] } + w_cin3;
    assign w_cout[3] = w_ALUMODE10_p3 ^ w_sum3[12];

    // ============================== XOR ==============================
    
    wire  [7:0] w_XORA;
    wire  [7:0] w_XORB;
    
    // XOR_12
    assign w_XORA[7] = ^w_S_alu[47:42];
    assign w_XORA[6] = ^w_S_alu[41:36];
    assign w_XORA[5] = ^w_S_alu[35:30];
    assign w_XORA[4] = ^w_S_alu[29:24];
    assign w_XORA[3] = ^w_S_alu[23:18];
    assign w_XORA[2] = ^w_S_alu[17:12];
    assign w_XORA[1] = ^w_S_alu[11: 6];
    assign w_XORA[0] = ^w_S_alu[ 5: 0];

    // XOR_24_48_96
    assign w_XORB[7] = 1'b0;
    assign w_XORB[6] = ^w_XORA[7:0];
    assign w_XORB[5] = ^w_XORA[7:4];
    assign w_XORB[4] = ^w_XORA[3:0];
    assign w_XORB[3] = ^w_XORA[7:6];
    assign w_XORB[2] = ^w_XORA[5:4];
    assign w_XORB[1] = ^w_XORA[3:2];
    assign w_XORB[0] = ^w_XORA[1:0];

    // ============================== ALU registers ==============================
    
    wire  [3:0] w_COUT_p3      = w_cout & w_cout_ena;
    wire [47:0] w_ALUOUT_p3    = (w_ALUMODE_mux[1])
                               ? ~{ w_sum3[11:0], w_sum2[11:0], w_sum1[11:0], w_sum0[11:0] }
                               :  { w_sum3[11:0], w_sum2[11:0], w_sum1[11:0], w_sum0[11:0] };
    wire  [7:0] w_XOROUT_p3    = (USE_WIDEXOR != "TRUE") ? 8'b0
                               : (XORSIMD == "XOR12") ? w_XORA : w_XORB;
    wire        w_MULTSIGN_p3  = w_sum3[13];
    wire        w_ALUMODE10_p3 = &w_ALUMODE_mux[1:0];

    reg   [3:0] r_COUT_p4;
    reg  [47:0] r_ALUOUT_p4;
    reg   [7:0] r_XOROUT_p4;
    reg         r_MULTSIGN_p4;
    reg         r_ALUMODE10_p4;
    
    always @(posedge w_CLK) begin : ALU_REG

        if (w_RSTP) begin
            r_COUT_p4      <= 4'b0;
            r_ALUOUT_p4    <= 48'b0;
            r_XOROUT_p4    <= 8'b0;
            r_MULTSIGN_p4  <= 1'b0;
            r_ALUMODE10_p4 <= 1'b0;
        end
        else if (CEP) begin
            r_COUT_p4      <= w_COUT_p3;
            r_ALUOUT_p4    <= w_ALUOUT_p3;
            r_XOROUT_p4    <= w_XOROUT_p3;
            r_MULTSIGN_p4  <= w_MULTSIGN_p3;
            r_ALUMODE10_p4 <= w_ALUMODE10_p3;
        end
    end

    assign P            = (PREG[0]) ? r_ALUOUT_p4   : w_ALUOUT_p3;
    assign PCOUT        = (PREG[0]) ? r_ALUOUT_p4   : w_ALUOUT_p3;
    assign XOROUT       = (PREG[0]) ? r_XOROUT_p4   : w_XOROUT_p3;
    assign CARRYOUT     = (PREG[0]) ? r_COUT_p4     : w_COUT_p3;
    assign MULTSIGNOUT  = (PREG[0]) ? r_MULTSIGN_p4 : w_MULTSIGN_p3;
    assign CARRYCASCOUT = (PREG[0]) ? r_ALUMODE10_p4 ^ r_COUT_p4[3]
                                    : w_ALUMODE10_p3 ^ w_COUT_p3[3];

    // ============================== Pattern detector ==============================
    
    wire [47:0] w_PATTERN_mux = (SEL_PATTERN == "PATTERN") ? PATTERN : w_C_p1;

    wire [47:0] w_MASK_mux    = (USE_PATTERN_DETECT == "NO_PATDET") ?    48'hFFFFFFFFFFFF
                              : (SEL_MASK == "C"                  ) ?    w_C_p1[47:0]
                              : (SEL_MASK == "ROUNDING_MODE1"     ) ? { ~w_C_p1[46:0], 1'b0 }
                              : (SEL_MASK == "ROUNDING_MODE2"     ) ? { ~w_C_p1[45:0], 2'b0 }
                              : MASK;

    wire w_PDET_p3  = &(~(w_PATTERN_mux ^ w_ALUOUT_p3) | w_MASK_mux);
    wire w_PDETB_p3 = &( (w_PATTERN_mux ^ w_ALUOUT_p3) | w_MASK_mux);

    reg  r_PDET_p4;
    reg  r_PDETB_p4;

    reg  r_PDET_p5;
    reg  r_PDETB_p5;

    always @(posedge w_CLK) begin : DET_REG

        if (w_RSTP) begin
           r_PDET_p5  <= 1'b0;
           r_PDETB_p5 <= 1'b0;
           r_PDET_p4  <= 1'b0;
           r_PDETB_p4 <= 1'b0;
        end
        else if (CEP) begin
           r_PDET_p5  <= r_PDET_p4;
           r_PDETB_p5 <= r_PDETB_p4;
           r_PDET_p4  <= w_PDET_p3;
           r_PDETB_p4 <= w_PDETB_p3;
        end
    end
    
    wire w_PDET_mux  = (PREG[0]) ? r_PDET_p4  : w_PDET_p3;
    wire w_PDETB_mux = (PREG[0]) ? r_PDETB_p4 : w_PDETB_p3;
    wire w_OVER_mux  = (PREG[0]) ? r_PDET_p5  : w_PDET_p3;
    wire w_UNDER_mux = (PREG[0]) ? r_PDETB_p5 : w_PDETB_p3;

    assign PATTERNDETECT  = w_PDET_mux;
    assign PATTERNBDETECT = w_PDETB_mux;

    assign OVERFLOW       = (USE_PATTERN_DETECT == "PATDET")
                          ? ~w_PDET_mux & ~w_PDETB_mux & w_OVER_mux : 1'b0;
    assign UNDERFLOW      = (USE_PATTERN_DETECT == "PATDET")
                          ? ~w_PDET_mux & ~w_PDETB_mux & w_UNDER_mux : 1'b0;

endmodule
/* verilator coverage_on */
