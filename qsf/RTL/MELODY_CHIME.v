// ===================================================================
// TITLE : CQ-EXT Melody Chime sample
//
//     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
//     DATE   : 2012/08/17 -> 2012/08/28
//            : 2012/08/28 (FIXED)
//
//     UPDATE : 2017/11/01we :mod Verilog
//              2015/03/14
// ===================================================================
// *******************************************************************
//   Copyright (C) 2012,2015 J-7SYSTEM Works.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

module MELODY_CHIME 
#(
    parameter C_SYS_CK_FREQ = 48_000_000 //48MHz(CQMAX10)/ 50MHz(DE0)
) (
      input         CK_i            // system clock
    , input tri1    XARST_i         // async XARST_i
    , input tri0    START_i         // play start('1':start)
    , output        TIMING_1MS_o    // 1ms timig pulse out
    , output        AUDIO_L_o       // 1bitDSM-DAC
    , output        AUDIO_R_o       // 1bitDSM-DAC
    , output        TEMPO_LED_o     //
    , output [3:0]  DB_SCORE_LEDs_o
) ;
    // log2() for calc bit width from data N
    // constant function on Verilog 2001
    function integer log2 ;
        input integer value ;
    begin
        value = value - 1 ;
        for (log2=0 ; value>0 ; log2=log2+1)
            value = value>>1 ;
    end 
    endfunction

    localparam C_1MS_DIV_LEN = C_SYS_CK_FREQ/100000;
    localparam C_DIV_CTR_W    = log2( C_1MS_DIV_LEN ) ;

    // used module
    // MELODY_CHIME_SEQ() ;
    // MELODY_CHIME_SG() ;




//    signal slot_div_sig     : std_logic_vector(7 downto 0);
//    signal slot_note_sig    : std_logic;
//    signal slot0_wrreq_sig  : std_logic;
//    signal slot1_wrreq_sig  : std_logic;

//    signal wav_add_sig      : std_logic_vector(C_DAT_W-1 downto 0);
//    signal pcm_sig          : std_logic_vector(C_DAT_W-1 downto 0);
                                              //9+1=10
//    signal add_sig          : std_logic_vector(pcm_sig'left+1 downto 0);
                                            //10-1=9
//    signal dse_reg          : std_logic_vector(add_sig'left-1 downto 0);
//    signal dacout_reg       : std_logic;


    // �^�C�~���O�p���X���� 
    reg [C_DIV_CTR_W-1:0]   US10_CTR    ;
    reg [log2(100)-1:0]     MS1_CTR     ;
    reg                     TIMING_10US ;
    reg                     TIMING_1MS  ;
    reg                     TEMPO_LED   ;
    wire        temp_ee ;
    always @ (posedge CK_i or negedge XARST_i)
        if( ~ XARST_i )
        begin
            US10_CTR    <= 'd0 ;
            MS1_CTR     <= 'd0 ;
            TIMING_10US <= 1'b0 ;
            TIMING_1MS  <= 1'b0 ;
            TEMPO_LED   <= 1'b0 ;
        end else
        begin
            if(US10_CTR == 0)
            begin
                US10_CTR <= C_1MS_DIV_LEN - 1;
                if(MS1_CTR == 0)
                    MS1_CTR <= 99;
                else 
                    MS1_CTR <= MS1_CTR - 1;
            end else
                US10_CTR <= US10_CTR - 1;

            TIMING_10US <= (US10_CTR == 0) ;
            TIMING_1MS  <= (US10_CTR == 0 && MS1_CTR == 0) ;

            if( temp_ee  )
                TEMPO_LED <=  ~ TEMPO_LED ;
        end
    assign TIMING_1MS_o = TIMING_1MS    ;
    assign TEMPO_LED_o  = TEMPO_LED     ;


    // �X�^�[�g�L�[���� 
    reg [ 2 :0]             START_IN_SFTREG     ;
    wire                    start               ;
    always @ (posedge CK_i or negedge XARST_i)
        if( ~ XARST_i )
            START_IN_SFTREG <= 3'b000 ;
        else
            if(TIMING_1MS)
                START_IN_SFTREG <= {START_IN_SFTREG[1:0] , ~ START_i} ;
    assign start = (START_IN_SFTREG[2:1] == 2'b01) ;


    // �V�[�P���T�C���X�^���X 
    wire[ 6:0]  SLOT_divs       ;
    wire        SLOT_note       ;
    wire[1:0]   SLOTs_WT_REQ    ;
    MELODY_CHIME_SEQ 
    #(
        .C_TEMPO_TC   ( 357 )// �e���|�J�E���^(357ms/Tempo=84) ) 
    ) MELODY_CHIME_SEQ
    (
          .CK_i             ( CK_i          )
        , .XAR_i            ( XARST_i       )
        , .TIMING_1ms_i     ( TIMING_1MS    )
        , .START_i          ( start         )
        , .tempo_o          ( temp_ee       )
        , .SLOT_divs_o      ( SLOT_divs     )
        , .SLOT_note_o      ( SLOT_note     )
        , .SLOTs_WT_REQ_o   ( SLOTs_WT_REQ  )
        , .DB_SCORE_ADRs_o  ( DB_SCORE_LEDs_o    )
    ) ;
    

    // �����X���b�g�C���X�^���X 
    wire [15:0] WAVEs_SLOTs [0:1];
    generate
        genvar g_i ;
        for(g_i=0;g_i<2;g_i=g_i+1)
        begin :gen_MELODY_CHIME_SG
            MELODY_CHIME_SG
            #(
                .C_ENVELOPE_TC        ( 28000 )// �G���x���[�v���萔(�ꎟ�x��n,t=0.5�b)
            ) MELODY_CHIME_SG
            (
                  .CK_i             ( CK_i                  )
                , .XARST_i          ( XARST_i               )
                , .EE_100KHZ_i      ( TIMING_10US           )
                , .EE_1KHZ_i        ( TIMING_1MS            )
                , .WE_i             ( SLOTs_WT_REQ  [ g_i ] )
                , .DIV_LENs_i       ( SLOT_divs             )
                , .SOUND_ON_i       ( SLOT_note             )
                , .WAVEs_o          ( WAVEs_SLOTs   [ g_i ] )
            ) ; 
        end
    endgenerate

    // �g�`���Z��1bitDSM-DAC
    wire [9:0] WAVEs_add ;
    assign WAVEs_add = 
        {WAVEs_SLOTs[0][15] , WAVEs_SLOTs[0][15 : 7]}
        + 
        {WAVEs_SLOTs[1][15] , WAVEs_SLOTs[1][15 : 7]}
    ;
    DELTA_SIGMA_1BIT_DAC 
    #(
        .C_DAT_W ( 10)
    ) DELTA_SIGMA_1BIT_DAC 
    (
          .CK       ( CK_i      )
        , .XARST_i  ( XARST_i   )
        , .DAT_i    ( WAVEs_add )
        , .QQ_o     ( AUDIO_L_o )
        , .XQQ_o    ( AUDIO_R_o )
    ) ;
endmodule
// MELODY_CHIME
