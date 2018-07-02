// ===================================================================
//蛸入りsjis
// TITLE : Melody Chime / Score Sequencer
//
//     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
//     DATE   : 2012/08/28 -> 2012/08/28
//            : 2012/08/28 (FIXED)
//
//     UPDATE : 2015/03/14
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

module MELODY_CHIME_SEQ
#(
    parameter integer C_TEMPO_TC = 357// テンポカウンタ(357ms/Tempo=84)
)(
      input          CK_i           // system clock
    , input tri1     XAR_i          // async system reset L
    , input         TIMING_1ms_i    // clock enable (1msタイミング,1パルス幅,1アクティブ) 
    , input         START_i         // '1'パルスで再生開始 
    , output        tempo_o         // テンポ信号出力 (1パルス幅,1アクティブ)
    , output[ 7 :0] SLOT_divs_o     // スロットの音程データ 
    , output        SLOT_note_o     // スロットの発音 1:on
    , output[ 1 :0] SLOTs_WT_REQ_o //スロット1,0への書き込み要求 

    , output [ 3 :0]  DB_SCORE_ADRs_o
) ;
    localparam C_R      = 5'b0_0000 ;  //  O4G+
    localparam C_O4Gp   = 5'b0_0000 ;  //  O4G+
    localparam C_O4A    = 5'b0_0001 ;  //  O4A
    localparam C_O4Ap   = 5'b0_0010 ;  //  O4A+
    localparam C_O4B    = 5'b0_0011 ;  //  O4B
    localparam C_O5C    = 5'b0_0100 ;  //  O5C
    localparam C_O5Cp   = 5'b0_0101 ;  //  O5C+
    localparam C_O5D    = 5'b0_0110 ;  //  O5D
    localparam C_O5Dp   = 5'b0_0111 ;  //  O5D+
    localparam C_O5E    = 5'b0_1000 ;  //  O5E
    localparam C_O5F    = 5'b0_1001 ;  //  O5F
    localparam C_O5Fp   = 5'b0_1010 ;  //  O5F+
    localparam C_O5G    = 5'b0_1011 ;  //  O5G
    localparam C_O5Gp   = 5'b0_1100 ;  //  O5G+
    localparam C_O5A    = 5'b0_1101 ;  //  O5A
    localparam C_O5Ap   = 5'b0_1110 ;  //  O5A+
    localparam C_O5B    = 5'b0_1111 ;  //  O5B
    localparam C_O6C    = 5'b1_0000 ;  //  O6C
    localparam C_O6Cp   = 5'b1_0001 ;  //  O6C+
    localparam C_O6D    = 5'b1_0010 ;  //  O6D
    localparam C_O6Dp   = 5'b1_0011 ;  //  O6D+
    localparam C_O6E    = 5'b1_0100 ;  //  O6E
    localparam C_O6F    = 5'b1_0101 ;  //  O6F
    localparam C_O6Fp   = 5'b1_0110 ;  //  O6F+
    localparam C_O6G    = 5'b1_0111 ;  //  O6G
    localparam C_O6Gp   = 5'b1_1000 ;  //  O6G+
    localparam C_O6A    = 5'b1_1001 ;  //  O6A
    localparam C_O6Ap   = 5'b1_1010 ;  //  O6A+
    localparam C_O6B    = 5'b1_1011 ;  //  O6B
    localparam C_O7C    = 5'b1_1100 ;  //  O7C
    localparam C_O7Cp   = 5'b1_1101 ;  //  O7C+
    localparam C_O7D    = 5'b1_1110 ;  //  O7D
    localparam C_O7Dp   = 5'b1_1111 ;  //  O7D+

    localparam C_SCORE_W    = 4                 ;
    localparam C_SCORE_LEN  = 2 ** C_SCORE_W    ;
    localparam C_SLOT_W     = 1                 ;
    localparam C_SLOT_LEN   = 2 ** C_SLOT_W     ;

//    wire    [5:0]   SCOREss [0 : C_SCORE_LEN*C_SLOT_LEN]    ;

    reg [C_SCORE_W-1:0] SCORE_CTRs          ;
    reg                 PLAY         ;
    reg                 T_DLY_D       ;
    reg [C_SLOT_W-1:0]  SLOT_CTRs        ;
    reg                 SLOT         ;

    reg [ 5 :0]         SCOREs      ;
    reg [ 7 :0]         SLOT_DIVs   ;
    reg [C_SLOT_LEN-1:0]  WT_REQs        ;


    assign DB_SCORE_ADRs_o = SCORE_CTRs[3 :0] ;


    // 楽譜データ 
    function [ 5 :0]  f_SCOREs ;
        input [$clog2(C_SCORE_LEN*2)-1:0]adr ;
    begin
        case ( adr )
            (C_SCORE_LEN*0 + 0): f_SCOREs = {1'b1 , C_O6G } ;
            (C_SCORE_LEN*0 + 1): f_SCOREs = {1'b1 , C_O6Dp} ;
            (C_SCORE_LEN*0 + 2): f_SCOREs = {1'b1 , C_O5Ap} ;
            (C_SCORE_LEN*0 + 3): f_SCOREs = {1'b1 , C_O6Dp} ;
            (C_SCORE_LEN*0 + 4): f_SCOREs = {1'b1 , C_O6F } ;
            (C_SCORE_LEN*0 + 5): f_SCOREs = {1'b1 , C_O6Ap} ;
            (C_SCORE_LEN*0 + 6): f_SCOREs = {1'b0 , C_O6Ap} ;
            (C_SCORE_LEN*0 + 7): f_SCOREs = {1'b1 , C_O5F } ;
            (C_SCORE_LEN*0 + 8): f_SCOREs = {1'b1 , C_O6F } ;
            (C_SCORE_LEN*0 + 9): f_SCOREs = {1'b1 , C_O6G } ;
            (C_SCORE_LEN*0 +10): f_SCOREs = {1'b1 , C_O6F } ;
            (C_SCORE_LEN*0 +11): f_SCOREs = {1'b1 , C_O5Ap} ;
            (C_SCORE_LEN*0 +12): f_SCOREs = {1'b1 , C_O6Dp} ;
            (C_SCORE_LEN*0 +13): f_SCOREs = {1'b0 , C_O6Dp} ;
            (C_SCORE_LEN*0 +14): f_SCOREs = {1'b0 , C_O6Dp} ;
            (C_SCORE_LEN*0 +15): f_SCOREs = {1'b0 , C_O6Dp} ;

            (C_SCORE_LEN*1 + 0): f_SCOREs = {1'b0 , C_R   } ;
            (C_SCORE_LEN*1 + 1): f_SCOREs = {1'b0 , C_R   } ;
            (C_SCORE_LEN*1 + 2): f_SCOREs = {1'b1 , C_O5G } ;
            (C_SCORE_LEN*1 + 3): f_SCOREs = {1'b0 , C_O5G } ;
            (C_SCORE_LEN*1 + 4): f_SCOREs = {1'b1 , C_O6D } ;
            (C_SCORE_LEN*1 + 5): f_SCOREs = {1'b0 , C_O6D } ;
            (C_SCORE_LEN*1 + 6): f_SCOREs = {1'b0 , C_R   } ;
            (C_SCORE_LEN*1 + 7): f_SCOREs = {1'b0 , C_R   } ;
            (C_SCORE_LEN*1 + 8): f_SCOREs = {1'b1 , C_O5Ap} ;
            (C_SCORE_LEN*1 + 9): f_SCOREs = {1'b0 , C_O5Ap} ;
            (C_SCORE_LEN*1 +10): f_SCOREs = {1'b1 , C_O5Ap} ;
            (C_SCORE_LEN*1 +11): f_SCOREs = {1'b0 , C_O5Ap} ;
            (C_SCORE_LEN*1 +12): f_SCOREs = {1'b1 , C_O5G } ;
            (C_SCORE_LEN*1 +13): f_SCOREs = {1'b0 , C_O5G } ;
            (C_SCORE_LEN*1 +14): f_SCOREs = {1'b0 , C_O5G } ;
            (C_SCORE_LEN*1 +15): f_SCOREs = {1'b0 , C_O5G } ;
            default :
                f_SCOREs = 6'b11_1111 ;
        endcase
    end 
    endfunction

    // テンポタイミングおよびスタート信号発生 
    localparam C_TEMPO_TC_W = $clog2( C_TEMPO_TC ) ;
    reg  [C_TEMPO_TC_W-1:0] TEMPO_CTR       ;
    wire TEMPO_sig        ;
    reg  START_D        ;

    assign TEMPO_sig = (TIMING_1ms_i &  (TEMPO_CTR == 0))  ;
    always@(posedge CK_i or negedge XAR_i)
        if ( ~ XAR_i ) 
        begin
            TEMPO_CTR <= 0 ;
            START_D   <= 0 ;
        end else 
        begin
            if( TIMING_1ms_i ) 
                if( TEMPO_CTR == {(C_TEMPO_TC_W){1'b0}} )
                    TEMPO_CTR <= C_TEMPO_TC - 1 ;
                else
                    TEMPO_CTR <= TEMPO_CTR - 1 ;
            if( START_i )
                START_D <= 1'b1 ;
            else if( TEMPO_sig )
                START_D <= 1'b0 ;
        end

    assign tempo_o = TEMPO_sig ;


    // スコアシーケンサ 
    always@(posedge CK_i or negedge XAR_i)
        if( ~ XAR_i ) 
        begin
            PLAY   <= 0 ;
            SCORE_CTRs <= 0;
            T_DLY_D <= 1'b0;
            SLOT   <= 1'b0;
            SLOT_CTRs  <= 0;
        end else
        begin
            if( TEMPO_sig )
                if( START_D )
                begin
                    PLAY <= 1'b1 ;
                    SCORE_CTRs <= 0;
                end else if(SCORE_CTRs == (C_SCORE_LEN - 1))
                    PLAY <= 1'b0;
                else if( PLAY )
                    SCORE_CTRs <= SCORE_CTRs + 1;
            T_DLY_D <= TEMPO_sig ;
            if( T_DLY_D )
            begin
                SLOT <= PLAY ;
                SLOT_CTRs <= 0 ;
            end else if(SLOT_CTRs == ( C_SLOT_LEN - 1))
                SLOT  <= 0 ;
            else
                SLOT_CTRs <= SLOT_CTRs + 1;
        end
    wire [$clog2(C_SCORE_LEN*2)-1:0] SCORE_adrs ;
    assign SCORE_adrs = SLOT_CTRs*C_SCORE_LEN + SCORE_CTRs  ;
    // 楽譜読み出し 
    always@(posedge CK_i or negedge XAR_i)
        if( ~ XAR_i ) 
            SCOREs <= 0 ;
        else
            SCOREs <= f_SCOREs(  SCORE_adrs ) ;

    generate
        genvar g_i ;
        for(g_i=0 ; g_i<C_SLOT_LEN ;g_i=g_i+1)
        begin :gen_WT_REQ
            always@(posedge CK_i or negedge XAR_i)
                if( ~ XAR_i )
                    WT_REQs[g_i] <= 0 ;
                else
                    if(g_i == SLOT_CTRs)
                        WT_REQs[g_i] <= SLOT ;
                    else
                        WT_REQs[g_i] <= 1'b0 ;
        end
    endgenerate

    // 音階データ→分周値変換 
    function [ 7:0] f_SLOT_divs ;
        input [ 5 :0] CODE ;
    begin
        case( CODE )
            C_O4Gp:   f_SLOT_divs = (241-1) ; //  O4G+    207.652Hz
            C_O4A :   f_SLOT_divs = (227-1) ; //  O4A     220.000Hz
            C_O4Ap:   f_SLOT_divs = (215-1) ; //  O4A+    233.082Hz
            C_O4B :   f_SLOT_divs = (202-1) ; //  O4B     246.942Hz
            C_O5C :   f_SLOT_divs = (191-1) ; //  O5C     261.626Hz
            C_O5Cp:   f_SLOT_divs = (180-1) ; //  O5C+    277.183Hz
            C_O5D :   f_SLOT_divs = (170-1) ; //  O5D     293.665Hz
            C_O5Dp:   f_SLOT_divs = (161-1) ; //  O5D+    311.127Hz
            C_O5E :   f_SLOT_divs = (152-1) ; //  O5E     329.628Hz
            C_O5F :   f_SLOT_divs = (143-1) ; //  O5F     349.228Hz
            C_O5Fp:   f_SLOT_divs = (135-1) ; //  O5F+    369.994Hz
            C_O5G :   f_SLOT_divs = (128-1) ; //  O5G     391.995Hz
            C_O5Gp:   f_SLOT_divs = (120-1) ; //  O5G+    415.305Hz
            C_O5A :   f_SLOT_divs = (114-1) ; //  O5A     440.000Hz
            C_O5Ap:   f_SLOT_divs = (107-1) ; //  O5A+    466.164Hz
            C_O5B :   f_SLOT_divs = (101-1) ; //  O5B     493.883Hz
            C_O6C :   f_SLOT_divs = ( 96-1) ; //  O6C     523.251Hz
            C_O6Cp:   f_SLOT_divs = ( 90-1) ; //  O6C+    554.365Hz
            C_O6D :   f_SLOT_divs = ( 85-1) ; //  O6D     587.330Hz
            C_O6Dp:   f_SLOT_divs = ( 80-1) ; //  O6D+    622.254Hz
            C_O6E :   f_SLOT_divs = ( 76-1) ; //  O6E     659.255Hz
            C_O6F :   f_SLOT_divs = ( 72-1) ; //  O6F     698.456Hz
            C_O6Fp:   f_SLOT_divs = ( 68-1) ; //  O6F+    739.989Hz
            C_O6G :   f_SLOT_divs = ( 64-1) ; //  O6G     783.991Hz
            C_O6Gp:   f_SLOT_divs = ( 60-1) ; //  O6G+    830.609Hz
            C_O6A :   f_SLOT_divs = ( 57-1) ; //  O6A     880.000Hz
            C_O6Ap:   f_SLOT_divs = ( 54-1) ; //  O6A+    932.328Hz
            C_O6B :   f_SLOT_divs = ( 51-1) ; //  O6B     987.767Hz
            C_O7C :   f_SLOT_divs = ( 48-1) ; //  O7C     1046.502Hz
            C_O7Cp:   f_SLOT_divs = ( 45-1) ; //  O7C+    1108.731Hz
            C_O7D :   f_SLOT_divs = ( 43-1) ; //  O7D     1174.659Hz
            C_O7Dp:   f_SLOT_divs = ( 40-1) ; //  O7D+    1244.508Hz
            default :
                f_SLOT_divs = 7'h00 ;
        endcase
    end
    endfunction
   
   
   
    // スロット制御信号出力 
    assign SLOT_note_o = SCOREs[5] ;
    assign SLOT_divs_o  = f_SLOT_divs( SCOREs[4:0] ) ;
//    always@(posedge CK_i or negedge XAR_i)
//        if( ~ XAR_i)
//            SLOT_DIVs <= 0 ;
//        else
//            SLOT_DIVs <= f_SLOT_divs( SCOREs[4:0] ) ;
//    assign SLOT_DIVs_o = SLOT_DIVs ;
//    reg     SLOT_NOTE   ;
//    always@(posedge CK_i or negedge XAR_i)
//        if( ~ XAR_i)
//            SLOT_NOTE <= 0 ;
//        else
//            SLOT_NOTE <= SCOREs[ 5 ] ;
//    assign SLOT_NOTE_o = SLOT_NOTE ;
    assign SLOTs_WT_REQ_o  = WT_REQs ;
endmodule
//MELODY_CHIME_SEQ()
