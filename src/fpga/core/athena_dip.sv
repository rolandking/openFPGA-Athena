`timescale 1ns/1ps

module athena_dip(
    bus_if                 bridge,
    output logic [15:0]    dip_switches,
    output athena::game_e  game
);

    // FIXME trim this further to the max number of bits for any entry
    // just store a byte
    logic [15:0][7:0] dip_mem;
    logic [3:0] dip_index;
    always_comb dip_index = bridge.addr[5:2];

    always_ff @(posedge bridge.clk) begin
        if(bridge.wr) begin
            dip_mem[dip_index] <= bridge.wr_data[7:0];
        end
        bridge.rd_data       <= {24'b0,dip_mem[dip_index]};
        bridge.rd_data_valid <= bridge.rd;
    end

    athena::dip_switch_athena_t dip_switch_athena;
    always_comb begin
        dip_switch_athena             = '0;
        dip_switch_athena.cabinet     = athena::athena_cabinet_e'(dip_mem[0]);
        dip_switch_athena.lives       = athena::athena_lives_e'(dip_mem[1]);
        dip_switch_athena.coin_a      = athena::athena_coin_a_e'(dip_mem[2]);
        dip_switch_athena.coin_b      = athena::athena_coin_b_e'(dip_mem[3]);
        dip_switch_athena.difficulty  = athena::athena_difficulty_e'(dip_mem[4]);
        dip_switch_athena.demo_sounds = athena::athena_demo_sounds_e'(dip_mem[5]);
        dip_switch_athena.bonus_life  = athena::athena_bonus_life_e'(dip_mem[6]);
        dip_switch_athena.energy      = athena::athena_energy_e'(dip_mem[7]);
    end

    athena::dip_switch_fighting_golf_t dip_switch_fighting_golf;
    always_comb begin
        dip_switch_fighting_golf                  = '0;
        dip_switch_fighting_golf.language         = athena::fg_language_e'(dip_mem[0]);
        dip_switch_fighting_golf.flip_screen      = athena::fg_flip_screen_e'(dip_mem[1]);
        dip_switch_fighting_golf.cabinet          = athena::fg_cabinet_e'(dip_mem[2]);
        dip_switch_fighting_golf.gameplay         = athena::fg_gameplay_e'(dip_mem[3]);
        dip_switch_fighting_golf.coin_a           = athena::fg_coin_a_e'(dip_mem[4]);
        dip_switch_fighting_golf.coin_b           = athena::fg_coin_b_e'(dip_mem[5]);
        dip_switch_fighting_golf.shot_time        = athena::fg_shot_time_e'(dip_mem[6]);
        dip_switch_fighting_golf.bonus_holes      = athena::fg_bonus_holes_e'(dip_mem[7]);
        dip_switch_fighting_golf.game_mode        = athena::fg_game_mode_e'(dip_mem[8]);
        dip_switch_fighting_golf.play_holes       = athena::fg_play_holes_e'(dip_mem[9]);
        dip_switch_fighting_golf.allow_continue   = athena::fg_allow_continue_e'(dip_mem[10]);
        dip_switch_fighting_golf.test_mode        = athena::fg_test_mode_e'(dip_mem[11]);
    end

    always_comb begin
        dip_switches = '0;
        game = athena::game_e'(dip_mem[15]);
        case(game)
            athena::game_athena: begin
                dip_switches = athena::dip_switch_athena_map(dip_switch_athena);
            end
            athena::game_fighting_golf: begin
                dip_switches = athena::dip_switch_fighting_golf_map(dip_switch_fighting_golf);
            end
            default: begin
                dip_switches = athena::dip_switch_athena_map(dip_switch_athena);
            end
        endcase
    end

endmodule
