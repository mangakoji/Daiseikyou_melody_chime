//TOP.v
//       top
//      
// 
//151230we      :trans for BeMicroMAX10
// CQEXT_melodychime base by @s_osafune tw
// base Copyright (c) 2015 by Semillero ADT. 
//                     web: https://sites.google.com/site/semilleroadt/
//                     email: semilleroadtupb@gmail.com
// Major Functions: BE-MICRO MAX10 TOP
//

module TOP(
        //CLOCKS
          CLK_50M_i
        , CLK_USR_i

        //LED
        , LED_o

        //SW
        , PSW_i

        //FLASH
        , SFLASH_DCLK
        , SFLASH_ASDI
        , SFLASH_CSn
        , SFLASH_DATA

        //AD5681R
        , AD5681R_LDACn
        , AD5681R_RSTn
        , AD5681R_SCL
        , AD5681R_SDA
        , AD5681R_SYNCn

        //ACCELEROMETER
        , ADXL362_CSn
        , ADXL362_MISO
        , ADXL362_MOSI
        , ADXL362_SCLK
        , ADXL362_INT1
        , ADXL362_INT2

        //ADT7420 Temperature Sensor
        , ADT7420_CT
        , ADT7420_INT
        , ADT7420_SCL
        , ADT7420_SDA

        //SDRAM
        , SDRAM_A
        , SDRAM_BA
        , SDRAM_CASn
        , SDRAM_CKE
        , SDRAM_CLK
        , SDRAM_CSn
        , SDRAM_DQ
        , SDRAM_RASn
        , SDRAM_WEn
        , SDRAM_DQM


        //PMOD_[A:D]
        , PMOD_A_io
        , PMOD_B_io
        , PMOD_C_io
        , PMOD_D_io

        //GPIO_[0:2]/DIFF
        , GPIO_0_io
        , GPIO_1_io
        , GPIO_2_io
        
) ;
        //CLOCKS
        input           CLK_50M_i          ;
        input           CLK_USR_i        ;

        //LED_o
        output [ 7 :0]  LED_o             ; //light : L

        //PSW_i
        input  [ 3 :0]  PSW_i              ;

        //FLASH
        output          SFLASH_DCLK     ;
        output          SFLASH_ASDI     ;
        output          SFLASH_CSn      ;
        input           SFLASH_DATA     ;

        //AD5681R
        output          AD5681R_LDACn   ;
        output          AD5681R_RSTn    ;
        output          AD5681R_SCL     ;
        output          AD5681R_SDA     ;
        output          AD5681R_SYNCn   ;

        //ACCELEROMETER
        output          ADXL362_CSn     ;
        input           ADXL362_MISO    ;
        output          ADXL362_MOSI    ;
        output          ADXL362_SCLK    ;
        input           ADXL362_INT1    ;
        input           ADXL362_INT2    ;

        //ADT7420 Temperature Sensor
        inout           ADT7420_SCL     ;
        inout           ADT7420_SDA     ;
        inout           ADT7420_CT      ;
        input           ADT7420_INT     ;


        //SDRAM
        output  [12 :0] SDRAM_A         ;
        output  [ 1 :0] SDRAM_BA        ;
        output          SDRAM_CASn      ;
        output          SDRAM_CKE       ;
        output          SDRAM_CLK       ;
        output          SDRAM_CSn       ;
        inout   [15 :0] SDRAM_DQ        ;
        output          SDRAM_RASn      ;
        output          SDRAM_WEn       ;
        output  [ 1 :0] SDRAM_DQM       ;


        //PMOD_[ A :D]
        inout   [ 3 :0] PMOD_A_io          ;
        inout   [ 3 :0] PMOD_B_io          ;
        inout   [ 3 :0] PMOD_C_io          ;
        inout   [ 3 :0] PMOD_D_io          ;

        //GPIO_[0:3]/DIFF
        inout   [35 :0] GPIO_0_io          ;
        inout   [25 :0] GPIO_1_io          ;
        //GPIO_2_io/EG
        inout   [55 :0] GPIO_2_io          ;

        // start
        wire            XAR             ;
        assign XAR = 1 ;
        wire    [ 3 :0] test_score_led  ;

        wire            start         ; //play start('1':start)
        wire            timing_1ms      ; //1ms timig pulse out
        wire            tempo_led       ;
        wire            aud_l           ; //1bitDSM-DAC
        assign start = ~ (& PSW_i) ;
        melodychime_top # (
                  .CLOCK_EDGE   ( 1'b1          ) //Rise edge drive clock
                , .RESET_LEVEL  ( 1'b0          ) //Positive logic reset
        ) u_melodychime_top(
                  .reset                ( XAR                   )
                , .clk                  ( CLK_50M_i             ) //system clock
                , .test_score_led       ( test_score_led        )
                , .start                ( start                 ) //play start('1':start)
                , .timing_1ms_out       ( timing_1ms            ) //1ms timig pulse out
                , .tempo_led            ( tempo_led             )
                , .aud_l_out            ( aud_l                 ) //1bitDSM-DAC
                , .aud_r_out            ()                        //same aud_l_out
        ) ; //melodychime_top
        assign LED_o = 
                { 
                  tempo_led 
                , test_score_led[0]
                , test_score_led[1]
                , test_score_led[2]
                , test_score_led[3]
                , 3'b111
                } ;
        assign PMOD_A_io[0] = aud_l ;
        assign PMOD_A_io[1] = ~ aud_l ;
        assign PMOD_B_io[0] = timing_1ms ;
endmodule //TOP
