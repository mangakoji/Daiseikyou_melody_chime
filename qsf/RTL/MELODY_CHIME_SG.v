// ===================================================================
// TITLE : Melody Chime / Sound Generator
//������ sjis
//
//     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
//
//     DATE   : 2012/08/17 -> 2012/08/28
//            : 2012/08/28 (FIXED)
//
//     UPDATE : 2017-11-04s
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

module MELODY_CHIME_SG 
#(
    parameter integer C_ENVELOPE_TC = 28000      // �G���x���[�v���萔(�ꎟ�x��n,t=0.5�b)
) 
(
      input             CK_i            // system clock
    , input tri1        XARST_i         // async system reset
    , input tri0 [ 7:0] DIV_LENs_i      // �����l�f�[�^(0�`255) 
    , input tri0        SOUND_ON_i      // �m�[�g�I��(1:�����J�n / 0:����) 
    , input tri0        WE_i            // 1=���W�X�^�������� 
    , input tri1        EE_100KHZ_i      // clock enable (10us�^�C�~���O,1�p���X��,1�A�N�e�B�u) 
    , input tri0        EE_1KHZ_i       // clock enable (1ms�^�C�~���O,1�p���X��,1�A�N�e�B�u) 

    , output [C_ENV_CTR_W : 0]     WAVEs_o              // �g�`�f�[�^�o��(�����t��16bit) 
) ;
    // ���̓��W�X�^ 
    reg [ 7:0] DIV_LENs ;
//    reg [ 7:0]  DIVREF_REG      ;
    reg         SOUND_ON        ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) 
        begin
            DIV_LENs     <= 8'd0 ;
            SOUND_ON    <= 1'b0 ;
        end else 
        begin
            if ( WE_i )
                DIV_LENs <= DIV_LENs_i ;
            SOUND_ON <= (WE_i & SOUND_ON_i) ;
        end


    // ��`�g���� 
    reg [ 7 :0] SQ_DIV_CTRs   ;
    reg         SQ_WAVE_POL  ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) 
        begin
            SQ_DIV_CTRs <= 8'd0 ;
            SQ_WAVE_POL <= 1'b0 ;
        end else 
            if ( EE_100KHZ_i )
                if (SQ_DIV_CTRs == 0)
                begin
                    SQ_DIV_CTRs <= DIV_LENs ;
                    SQ_WAVE_POL <= ~ SQ_WAVE_POL ;
                end else
                    SQ_DIV_CTRs <= SQ_DIV_CTRs - 1;


    // �G���x���[�v���� 
    localparam C_ENV_CTR_W = $clog2( C_ENVELOPE_TC ) ;
    reg [C_ENV_CTR_W-1 : 0]  ENV_CTRs    ;
    wire [(C_ENV_CTR_W+9)-1: 0] env_cnext_val ;
    // vonext = ((vo<<9) - vo)>>9
    assign env_cnext_val = 
        {ENV_CTRs , 9'b0_0000_0000} 
        - 
        {9'b0_0000_0000 , ENV_CTRs} 
    ;
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) 
            ENV_CTRs <= 15'd0 ;
        else
            if ( EE_1KHZ_i )
                if ( SOUND_ON )
                    ENV_CTRs <= (C_ENVELOPE_TC - 1) ;
                else if (ENV_CTRs != 0)
                    // vonext = ((vo<<9) - vo)>>9
                    ENV_CTRs <= env_cnext_val[9 +:15] ;


    // �g�`�U���ϒ��Əo�� 
    wire [C_ENV_CTR_W :0] WAVEs_pos     ;
    wire [C_ENV_CTR_W :0] WAVEs_neg     ;

    assign WAVEs_pos = { ENV_CTRs };
    assign WAVEs_neg = - $signed( WAVEs_pos );
    reg     [15 :0]  WAVEs ; //2's
    always @(posedge CK_i or negedge XARST_i)
        if ( ~ XARST_i) 
            WAVEs <= 'd0 ;//2's
        else
            WAVEs <= 
                ( ~ SQ_WAVE_POL)
                ?
                    WAVEs_pos
                :
                    WAVEs_neg
            ;
    assign WAVEs_o = WAVEs ;
endmodule

