//
// User core top-level
//
// Instantiated by the real top-level: apf_top
//

`default_nettype none

module user_top (

    input   wire            clk_74a, // mainclk1
    input   wire            clk_74b, // mainclk1

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    port_if                 port_cart_tran_bank0,

    // GBA A[23:16]
    port_if                 port_cart_tran_bank1,

    // GBA AD[15:8]
    port_if                 port_cart_tran_bank2,

    // GBA AD[7:0]
    port_if                 port_cart_tran_bank3,

    // GBA CS2#/RES#
    port_if                 port_cart_tran_pin30,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output  wire            cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    port_if                 port_cart_tran_pin31,

    // infrared
    ir_if                   ir,

    // GBA link port
    gba_if                  gba,

    cram_if                 cram0,
    cram_if                 cram1,
    dram_if                 dram,
    sram_if                 sram,

    input   wire            vblank,

    //
    // logical connections
    //

    video_if                video,
    audio_if                audio,

    output  logic           bridge_endian_little,
    bus_if                  bridge,

    controller_if           controller[1:4]
);
    typedef enum int {
        CMD = 0,
        DATASLOT = 1,
        ID = 2,
        ROM = 3,
        NUM_LEAVES
    } leaf_e;

    bus_if#(
        .addr_width  (32),
        .data_width  (32)
    ) bridge_out[NUM_LEAVES](.clk(clk_74a));

    localparam pocket::bridge_addr_range_t range_all[NUM_LEAVES] = '{
      '{from_addr : 32'hf8000000, to_addr : 32'hf8001fff},
      '{from_addr : 32'hf8002000, to_addr : 32'hf80020ff},
      '{from_addr : 32'hf8002380, to_addr : 32'hf80023ff},
      '{from_addr : 32'h00000000, to_addr : 32'h00100000}
    };

    bridge_master #(
        .ENDIAN_LITTLE     (1'b0),
        .NUM_LEAVES        (NUM_LEAVES),
        .ADDR_RANGES       (range_all)
        ) bm (
            .bridge_endian_little,
            .bridge_in             (bridge),
            .bridge_out            (bridge_out)
        );

    always_comb begin
        cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
        // tie the cart off
        port_cart_tran_bank0.tie_off_out(4'b1111);
        port_cart_tran_bank1.tie_off_in();
        port_cart_tran_bank2.tie_off_in();
        port_cart_tran_bank3.tie_off_in();
        port_cart_tran_pin30.tie_off_in();
        port_cart_tran_pin31.tie_off_in();

        // not using the IR port, so turn off both the LED, and
        // disable the receive circuit to save power
        ir.tie_off();

        gba.tie_off();

        cram0.tie_off();
        cram1.tie_off();

        // FIXME: put this back
        //dram.tie_off();

        sram.tie_off();

        //video.tie_off();
        //audio.tie_off();
    end

    bridge_pkg::host_request_status_result_e core_status;
    logic                                    reset_n;
    host_dataslot_request_read_if            host_dataslot_request_read();
    host_dataslot_request_write_if           host_dataslot_request_write();
    host_dataslot_update_if                  host_dataslot_update();
    host_dataslot_complete_if                host_dataslot_complete();
    host_rtc_update_if                       host_rtc_update();
    host_savestate_start_query_if            host_savestate_start_query();
    host_savestate_load_query_if             host_savestate_load_query();
    logic                                    in_menu;
    host_notify_cartridge_if                 host_notify_cartridge();
    logic                                    docked;
    host_notify_display_mode_if              host_notify_display_mode();

    core_ready_to_run_if                     core_ready_to_run();
    core_debug_event_log_if                  core_debug_event_log();
    core_dataslot_read_if                    core_dataslot_read();
    core_dataslot_write_if                   core_dataslot_write();
    core_dataslot_flush_if                   core_dataslot_flush();
    core_get_dataslot_filename_if            core_get_dataslot_filename();
    core_open_dataslot_file_if               core_open_dataslot_file();

    bridge_core bc(
        .bridge_cmd                        (bridge_out[CMD]),
        .bridge_id                         (bridge_out[ID]),
        .bridge_dataslot                   (bridge_out[DATASLOT]),
        .core_status,
        .reset_n,
        .host_dataslot_request_read,
        .host_dataslot_request_write,
        .host_dataslot_update,
        .host_dataslot_complete,
        .host_rtc_update,
        .host_savestate_start_query,
        .host_savestate_load_query,
        .in_menu,
        .host_notify_cartridge,
        .docked,
        .host_notify_display_mode,

        .core_ready_to_run,
        .core_debug_event_log,
        .core_dataslot_read,
        .core_dataslot_write,
        .core_dataslot_flush,
        .core_get_dataslot_filename,
        .core_open_dataslot_file
    );

    always_comb begin
        host_dataslot_request_read.tie_off();
        host_dataslot_request_write.tie_off();
        host_dataslot_update.tie_off();
        host_dataslot_complete.tie_off();
        host_rtc_update.tie_off();
        host_savestate_start_query.tie_off();
        host_savestate_load_query.tie_off();
        host_notify_cartridge.tie_off();
        //host_notify_display_mode.tie_off();

        core_status = bridge_pkg::host_request_status_result_default(pll_core_locked, reset_n, 1'b0);

        core_debug_event_log.tie_off();
        core_dataslot_read.tie_off();
        core_dataslot_write.tie_off();
        core_dataslot_flush.tie_off();
        core_get_dataslot_filename.tie_off();
        core_open_dataslot_file.tie_off();
    end

    video_if video_raw(
        .rgb_clock      (video.rgb_clock),
        .rgb_clock_90   (video.rgb_clock_90)
    );

    host_display_mode#(
        .supports_grayscale        (`SUPPORTS_GRAYSCALE)
    ) hdm (
        .clk                       (clk_74a),
        .host_notify_display_mode,
        .video_in                  (video_raw),
        .video_out                 (video)
    );

    logic pll_core_locked;
    core_ready_to_run crtr(
        .bridge_clk       (bridge.clk),
        .pll_core_locked,
        .reset_n,
        .core_ready_to_run
    );

    athena_top tt (
        .clk_74a,
        .reset_n,
        .pll_core_locked,
        .bridge_rom       (bridge_out[ROM]),
        .video            (video_raw),
        .audio,

        // FIXME: temp
        .dram
    );

endmodule
