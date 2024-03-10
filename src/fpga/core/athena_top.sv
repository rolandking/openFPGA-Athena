

module athena_top(
    input logic   clk_74a,
    input logic   reset_n,
    output logic  pll_core_locked,
    bus_if        bridge_rom,
    video_if      video,
    audio_if      audio,

    // FIXME: temp
    cram_if       cram
);

    /* main clock for Athena runs at 53.600MHz
     * which is too fast to be a dot clock.
     * generate 26.8Mhz dot clocks and sample
     * the outputs from the core
     */

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

    always_comb begin
        pause_cpu     =  ~reset_n;
        dsw1          = '0;
        dsw2          = '0;
        PLAYER1       = '1;
        PLAYER2       = '1;

        // FIXME: take a register or memory write to get the game
        game          = 8'h02;

        // FIXME: is this the screen flip?
        hack_settings = 8'b00000001;

        layer_ena_dbg = '1;
        dbg_B1Voffset = 4'b0011;
        swap_px       = '1;
    end

    bus_if#(
        .addr_width(32),
        .data_width(32)
    ) bridge_rom_cdc (.clk(clk_53_6_mhz));

    bridge_cdc rom_cdc(
        .in  (bridge_rom    ),
        .out (bridge_rom_cdc)
    );

    bus_if#(
        .addr_width(25),
        .data_width(8)
    ) mem(.clk(clk_53_6_mhz));

    bridge_to_bytes#(
        .CYCLES  (8)
    ) b2b(
        .bridge    (bridge_rom_cdc),
        .mem
    );

    bus_if#(
        .addr_width  (16),
        .data_width  (8)
    ) ym3256 (
        .clk  (clk_53_6_mhz)
    );

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
        .ioctl_addr          (mem.addr),
        .ioctl_wr            (mem.wr),
        .ioctl_data          (mem.wr_data),
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
        .snd2,

        .ym3256
    );

    ym3256_mem y_mem (
        .reset_n,
        .cram,
        .mem,
        .ym3256
    );

    edge_detect#(
        .positive  ('1)
    ) hsync_edge (
        .clk     (video.rgb_clock),
        .in      (HSYNC),
        .out     (video.hs)
    );

    // stretch the CE_PIXEL over two cycles
    logic ce_ff, ce_held;
    always @(posedge clk_53_6_mhz) begin
        ce_ff <= CE_PIXEL;
    end

    always_comb begin
        ce_held = CE_PIXEL | ce_ff;
    end


    edge_detect#(
        .positive  ('1)
    ) vsync_edge (
        .clk     (video.rgb_clock),
        .in      (VSYNC),
        .out     (video.vs)
    );

    always_comb begin
        video.de   = ~(VBLANK || HBLANK);
        video.skip = video.de && !ce_held;
        video.rgb  = video.de ? {R, 4'b0, G, 4'b0, B, 4'b0 } : 24'b0;
     end

endmodule
