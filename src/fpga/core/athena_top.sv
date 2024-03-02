

module athena_top(
    input logic   clk_74a,
    input logic   reset_n,
    output logic  pll_core_locked,
    bus_if        bridge_rom,
    video_if      video,
    audio_if      audio
);

    /* main clock for Athena runs at 53.600MHz
     * which is too fast to be a dot clock.
     * generate 26.8Mhz dot clocks and sample
     * the outputs from the core
     */

    /*
     * 26.8Mhz / 50 = 536,000 HZ
     * so set up for 1000 x 536 dots
     * for a refresh of 50Hhz
     */
    video_dummy#(
        .x_dots (1000),
        .y_dots (536)
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

endmodule
