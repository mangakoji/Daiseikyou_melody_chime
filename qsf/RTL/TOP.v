//TOP.v
//       TOP
//      
//170312u   :trans for CQ_MAX10
//151230we      :trans for BeMicroMAX10
// CQEXT_melodychime base by @s_osafune tw
// base Copyright (c) 2015 by Semillero ADT. 
//                     web: https://sites.google.com/site/semilleroadt/
//                     email: semilleroadtupb@gmail.com
// Major Functions: BE-MICRO MAX10 TOP
//

module TOP(
      input     CK48M_i     //27
    , input     XPSW_i      //123
    , output    XLED_R_o   //120
    , output    XLED_G_o   //122
    , output    XLED_B_o   //121
    // CN1
    , inout     P62
    , inout     P61
    , inout     P60
    , inout     P59
    , inout     P58
    , inout     P57
    , inout     P56
    , inout     P55
    , inout     P52
    , inout     P50
    , inout     P48
    , inout     P47
    , inout     P46
    , inout     P45
    , inout     P44
    , inout     P43
    , inout     P41
    , inout     P39
    , inout     P38
    // CN2
    , inout     P124
    , inout     P127
    , inout     P130
    , inout     P131
    , inout     P132
    , inout     P134
    , inout     P135
    , inout     P140
    , inout     P141
//    , inout     P3 //analog AD pin
    , inout     P6
    , inout     P7
    , inout     P8
    , inout     P10
    , inout     P11
    , inout     P12
    , inout     P13
    , inout     P14
    , inout     P17

) ;

    // start
    wire        CK50M   ;
    PLL PLL (
          .inclk0   ( CK48M_i   )
        , .areset   ( 1'b0      )
        , .c0       ( CK50M     )
        , .locked   ()
    ) ;

    wire            XAR             ;
    assign XAR = 1'b1 ;


    wire    [ 3 :0] test_score_led  ;
    wire            start           ; //play start('1':start)
    wire            timing_1ms      ; //1ms timig pulse out
    wire            tempo_led       ;
    wire            aud_l           ; //1bitDSM-DAC
    assign start = ~ XPSW_i ;
    melodychime_top # (
          .CLOCK_EDGE   ( 1'b1          ) //Rise edge drive clock
        , .RESET_LEVEL  ( 1'b0          ) //Positive logic reset
    ) u_melodychime_top(
          .reset            ( XAR               )
        , .clk              ( CK48M_i             ) //system clock
        , .test_score_led   ( test_score_led    )
        , .start            ( start             ) //play start('1':start)
        , .timing_1ms_out   ( timing_1ms        ) //1ms timig pulse out
        , .tempo_led        ( tempo_led         )
        , .aud_l_out        ( aud_l             ) //1bitDSM-DAC
        , .aud_r_out        ()                    //same aud_l_out
    ) ; //melodychime_top
    assign XLED_R_o = ~ tempo_led ;
    assign XLED_G_o = ~ test_score_led[0]   ;
    assign XLED_B_o = ~ timing_1ms ;
    assign P17 = aud_l ;
    assign P14 = ~ aud_l ;
endmodule //TOP
