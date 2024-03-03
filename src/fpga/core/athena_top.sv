

module athena_top(
    input logic   clk_74a,
    input logic   reset_n,
    output logic  pll_core_locked,
    bus_if        bridge_rom,
    video_if      video,
    audio_if      audio,

    // FIXME: temp
    dram_if       dram
);

    /* main clock for Athena runs at 53.600MHz
     * which is too fast to be a dot clock.
     * generate 26.8Mhz dot clocks and sample
     * the outputs from the core
     */

    /*
     * 26.8Mhz / 50 = 536,000 HZ
     * so set up for 1664 x 262 dots
     * 26800000 / 1664 / 262 == 61.47Hz
     * 1664 / 4 = 416 active dots
     *
     * visible screen size is 228 x 216
     */
    video_dummy#(
        .x_dots (1664),
        .y_dots (262),
        .x_px   (228),
        .y_px   (216),
        .duty   (4)
    ) vd (
        .video
    );

    audio_dummy ad(
        .clk_12_288_mhz,
        .audio
    );

    /* main clock for Athena runs at 53.600MHz
     * which is too fast to be a dot clock.
     * generate 26.8Mhz dot clocks and sample
     * the outputs from the core
     */

     logic clk_53_6_mhz;
     logic clk_26_8_mhz;
     logic clk_26_8_mhz_90;
     logic clk_12_288_mhz;

     always_comb begin
        video.rgb_clock    = clk_26_8_mhz;
        video.rgb_clock_90 = clk_26_8_mhz_90;
     end

     mf_pllbase mp1 (
        .refclk         ( clk_74a          ),
        .rst            ( 0                ),
        .outclk_0       ( clk_53_6_mhz     ),
        .outclk_1       ( clk_26_8_mhz     ),
        .outclk_2       ( clk_26_8_mhz_90  ),
        .outclk_3       ( clk_12_288_mhz   ),
        .locked         ( pll_core_locked  )
    );

    logic        pause_cpu;
    logic [7:0]  dsw1, dsw2;
    logic [15:0] PLAYER1, PLAYER2;
    logic [7:0]  game;
    logic [7:0]  hack_settings;
    logic [24:0] ioctl_addr;
    logic        ioctl_wr;
    logic [7:0]  ioctl_data;
    logic [2:0]  layer_ena_dbg;
    logic [3:0]  dbg_B1Voffset;
    logic        swap_px;
    logic [3:0]  R,G,B;
    logic        HBLANK, VBLANK, HSYNC, VSYNC, CE_PIXEL;
    logic signed [15:0] snd1, snd2;

    logic [15:0] x_clocks, x_ce_enable, y_lines, x_unblanked, y_unblanked, x_pixels;
    video_count(
        .clk  (clk_53_6_mhz),
        .HBLANK,
        .VBLANK,
        .CE_PIXEL,
        .x_clocks,
        .x_ce_enable,
        .y_lines,
        .x_unblanked,
        .y_unblanked,
        .x_pixels
    );

    /*
     * make an output so we can keep the hierarchy
     */
    logic [14:0] temp_hold /* synthesis keep */;
    always_comb begin
        temp_hold = {R,G,B,HBLANK,VBLANK,CE_PIXEL};

        dram.tie_off();
        dram.data_out = temp_hold;
    end

    always_comb begin
        pause_cpu    = '0;
        dsw1         = '0;
        dsw2         = '0;
        PLAYER1      = '1;
        PLAYER2      = '1;

        // FIXME: take a register or memory write to get the game
        game         = '0;

        // FIXME: is this the screen flip?
        hack_settings = 8'b00000001;

        ioctl_addr    = '0;
        ioctl_data    = '0;
        ioctl_wr      = '0;
        layer_ena_dbg = '1;
        dbg_B1Voffset = 4'b0011;
        swap_px       = '1;
    end

    AthenaCore snk_athena
    (
        .RESETn(reset_n),
        .VIDEO_RSTn(reset_n),
        .pause_cpu(pause_cpu),
        .i_clk(clk_53_6_mhz), //53.6MHz
        .DSW({dsw2,dsw1}),
        .PLAYER1,
        .PLAYER2,
        .TRACKBALL1('0),
        .TRACKBALL2('0),
        .GAME(game), //default ASO (ASO,Alpha Mission, Arian Mission)
        //HACK settings
        .hack_settings(hack_settings),
        //hps_io rom interface
        .ioctl_addr,
        .ioctl_wr,
        .ioctl_data,
        .layer_ena_dbg,
        .dbg_B1Voffset,
        .swap_px,
        //output
        .R,
        .G,
        .B,
        .HBLANK,
        .VBLANK,
        .HSYNC,
        .VSYNC,
        .CE_PIXEL,
        .snd1,
        .snd2
   );


endmodule
