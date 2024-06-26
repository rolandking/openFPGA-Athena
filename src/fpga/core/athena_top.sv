

module athena_top(
    input logic                    clk_74a,
    input logic                    reset_n,
    output logic                   pll_core_locked,
    bus_if                         bridge_rom,
    bus_if                         bridge_dip,
    bus_if                         bridge_hs,
    video_if                       video,
    audio_if                       audio,

    cram_if                        cram,
    input controller_t             controllers[1:4],
    input logic                    in_menu,

    // replace the size of the hiscore slot with the correct
    // size if not loaded so that it saves
    bus_if                         bridge_dataslot_in,
    bus_if                         bridge_dataslot_out,

    host_dataslot_request_write_if host_dataslot_request_write,
    core_dataslot_read_if          core_dataslot_read
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

    logic          hs_pause_req;
    logic          pause_cpu;
    logic [15:0]   dip_switches;
    logic [15:0]   PLAYER1, PLAYER2;
    athena::game_e game;
    logic [7:0]    hack_settings;
    logic [24:0]   ioctl_addr;
    logic          ioctl_wr;
    logic [7:0]    ioctl_data;
    logic [2:0]    layer_ena_dbg;
    logic [3:0]    dbg_B1Voffset;
    logic          swap_px;
    logic [3:0]    R,G,B;
    logic          HBLANK, VBLANK, HSYNC, VSYNC, CE_PIXEL;
    logic signed [15:0] snd1, snd2;
    logic [7:0] trackball_1_x, trackball_1_y;
    wire [15:0] trackball_1 = {trackball_1_x, trackball_1_y};

    pocket::key_t keys[1:2];
    ControllerToD#(
        .NUM_CONTROLLERS (2),
        .MAP_JOYSTICK    ('1)
    ) ctd (
        .controllers,
        .keys,
        .exists       ()
    );

    athena_dip ad(
        .bridge                 (bridge_dip),
        .dip_switches,
        .game
    );

    pocket::key_t k1, k2;
    always_comb begin
        k1            = keys[1];
        k2            = keys[2];
        pause_cpu     =  ~reset_n || in_menu || hs_pause_req;
        PLAYER1 = '1;
        PLAYER1 = {
            2'b11,
            ~k1.dpad_up,
            ~k1.dpad_down,
            ~k1.dpad_right,
            ~k1.dpad_left,
            1'b1,
            5'b11111,
            ~k1.face_b,
            ~k1.face_a,
            ~k1.face_start,
            ~k1.face_select
            };

        PLAYER2 = '1;
        PLAYER2 = {
            2'b11,
            ~k2.dpad_up,
            ~k2.dpad_down,
            ~k2.dpad_right,
            ~k2.dpad_left,
            1'b1,
            5'b11111,
            ~k2.face_b,
            ~k2.face_a,
            ~k2.face_start,
            ~k2.face_select
        };

        // FIXME: is this the screen flip? remove it and flip in video.json
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

    athena::side_ram_t side_ram_monitor;
    athena::side_ram_t side_ram_in;

    wire is_fighting_golf = (game == athena::game_fighting_golf);

    athena_hiscore hiscore(
        .bridge_hs,
        .game_clk          (clk_53_6_mhz),
        .side_ram_monitor,
        .side_ram_in,

        .bridge_dataslot_in,
        .bridge_dataslot_out,
        .host_dataslot_request_write,
        .core_dataslot_read,

        .hs_pause_req,
        .pause_cpu,

        .is_fighting_golf
    );

    AthenaCore snk_athena
    (
        .RESETn(reset_n),
        .VIDEO_RSTn(reset_n),
        .pause_cpu(pause_cpu),
        .i_clk(clk_53_6_mhz), //53.6MHz
        .DSW(dip_switches),
        .PLAYER1,
        .PLAYER2,
        .TRACKBALL1(trackball_1),
        .TRACKBALL2(trackball_1),
        .GAME(game),
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

        .ym3256,
        .side_ram_monitor,
        .side_ram_in
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

    logic signed [15:0] snd1_cdc, snd2_cdc;
    cdc_buffer#(
        .data_width (32)
    ) sound_cdc (
        .wr_clk   (clk_53_6_mhz),
        .wr_data  ({snd1, snd2}),
        .wr       ('1),

        .rd_clk   (clk_12_288_mhz),
        .rd_data  ({snd1_cdc, snd2_cdc})
    );

    audio_standard audio_out(
        .clk_12_288_mhz,

        .sound_l    (snd1_cdc),
        .sound_r    (snd2_cdc),

        .audio
    );

    // the trackball count 256 states, guessing it would take 4 seconds to
    // max it out in any direction that's 64 ticks per second.
    // the clock is 74.25MHz so we want to sample every 1,160,000 ticks
    // which is about 20 bits
    logic [19:0] track_counter, track_counter_next;
    always_comb track_counter_next = {1'b0,track_counter[18:0]} + 20'd1;
    always_ff @(posedge clk_74a) begin
        track_counter <= track_counter_next;

        if(track_counter[19]) begin

            trackball_1_x <= 0;
            trackball_1_y <= 0;

            if(k1.dpad_left) begin
                trackball_1_x <= 8'hb0;
            end
            if(k1.dpad_right) begin
                trackball_1_x <= 8'h40;
            end
            if(k1.dpad_up) begin
                trackball_1_y <= 8'hb0;
            end
            if(k1.dpad_down) begin
                trackball_1_y <= 8'h40;
            end
        end
    end


endmodule
