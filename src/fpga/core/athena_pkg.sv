package athena;

    typedef enum logic[7:0] {
        game_athena         = 8'h2,
        game_country_club   = 8'h14,
        game_fighting_golf  = 8'h4
    } game_e;

    typedef enum logic {
        athena_cabinet_uprights = 1'b0,
        athena_cabinet_cocktail = 1'b1
    } athena_cabinet_e;

    typedef enum logic {
        athena_lives_5          = 1'b0,
        athena_lives_3          = 1'b1
    } athena_lives_e;

    typedef enum logic[1:0]{
        athena_coin_a_4co_1cr = 2'b00,
        athena_coin_a_3co_1cr = 2'b01,
        athena_coin_a_2co_1cr = 2'b10,
        athena_coin_a_1co_1cr = 2'b11
    } athena_coin_a_e;

    typedef enum logic[1:0]{
        athena_coin_b_1co_2cr = 2'b00,
        athena_coin_b_1co_3cr = 2'b01,
        athena_coin_b_1co_4cr = 2'b10,
        athena_coin_a_1co_6cr = 2'b11
    } athena_coin_b_e;

    typedef enum logic[1:0]{
        athena_difficulty_hardest = 2'b00,
        athena_difficulty_hard    = 2'b01,
        athena_difficulty_normal  = 2'b10,
        athena_difficulty_easy    = 2'b11
    } athena_difficulty_e;

    typedef enum logic {
        athena_demo_sounds_on     = 1'b0,
        athena_demo_sounds_off    = 1'b1
    } athena_demo_sounds_e;

    typedef enum logic {
        athena_freeze_on          = 1'b0,
        athena_freeze_off         = 1'b1
    } athena_freeze_e;

    typedef enum logic[2:0] {
        athena_bonus_life_none        = 3'b000,
        athena_bonus_life_100_200     = 3'b010,
        athena_bonus_life_60_120      = 3'b100,
        athena_bonus_life_50_100      = 3'b110,
        athena_bonus_life_100_200_200 = 3'b011,
        athena_bonus_life_60_120_120  = 3'b101,
        athena_bonus_life_50_100_100  = 3'b111
    } athena_bonus_life_e;

    typedef enum logic {
        athena_energy_14 = 1'b0,
        athena_energy_12 = 1'b1
    } athena_energy_e;

    typedef struct packed {
        athena_energy_e       energy;
        athena_bonus_life_e   bonus_life;
        athena_freeze_e       freeze;
        athena_demo_sounds_e  demo_sounds;
        athena_difficulty_e   difficulty;
        athena_coin_b_e       coin_b;
        athena_coin_a_e       coin_a;
        athena_lives_e        lives;
        athena_cabinet_e      cabinet;
    } dip_switch_athena_t;

    function automatic logic[15:0] dip_switch_athena_map(dip_switch_athena_t d);
        return {
            d.energy,     1'b0, d.bonus_life[1:0],            1'b1, d.demo_sounds, d.difficulty,
            d.coin_b, d.coin_a, d.lives,           d.bonus_life[0], d.cabinet,             1'b0
        };
    endfunction

    function automatic dip_switch_athena_t dip_switch_athena_unmap(logic[15:0] l);
        dip_switch_athena_t d;
        logic _d1, _d2;
        {
            d.energy,      _d1, d.bonus_life[1:0], d.freeze,        d.demo_sounds, d.difficulty,
            d.coin_b, d.coin_a, d.lives,           d.bonus_life[0], d.cabinet,              _d1
        } = l;

        return d;
    endfunction

    parameter dip_switch_athena_t DIP_SWITCH_ATHENA_DEFAULT = '{
        energy      : athena_energy_12,
        bonus_life  : athena_bonus_life_100_200,
        freeze      : athena_freeze_off,
        demo_sounds : athena_demo_sounds_on,
        difficulty  : athena_difficulty_normal,
        coin_b      : athena_coin_b_1co_2cr,
        coin_a      : athena_coin_a_1co_1cr,
        lives       : athena_lives_5,
        cabinet     : athena_cabinet_cocktail
    };

    // 1001110011110111
    // 1                  - energy
    //  0                 - dummy
    //   01               - bonus_life[1:0]
    //     1              - freeze              (off)
    //      1             - demo sounds         (on)
    //       00           - difficulty          (hardest)
    //         11         - coin_b              (1co 6cr)
    //           11       - coin_a              (1co 1cr)
    //             0      - lives               (5)
    //              1     - bonus_life[0]  --> bonus_life == 010 == 100/200
    //               1    - cabinet             (cocktail)
    //                1   - dummy


    typedef enum logic {
        fg_language_japanese = 1'b0,
        fg_language_english  = 1'b1
    } fg_language_e;

    typedef enum logic {
        fg_flip_screen_on  = 1'b0,
        fg_flip_screen_off = 1'b1
    } fg_flip_screen_e;

    typedef enum logic {
        fg_cabinet_cocktail  = 1'b0,
        fg_cabinet_upright   = 1'b1
    } fg_cabinet_e;

    typedef enum logic {
        fg_gameplay_basic  = 1'b0,
        fg_gameplay_avid   = 1'b1
    } fg_gameplay_e;

    typedef enum logic[1:0]{
        fg_coin_a_4co_1cr = 2'b00,
        fg_coin_a_3co_1cr = 2'b01,
        fg_coin_a_2co_1cr = 2'b10,
        fg_coin_a_1co_1cr = 2'b11
    } fg_coin_a_e;

    typedef enum logic[1:0]{
        fg_coin_b_1co_2cr = 2'b00,
        fg_coin_b_1co_3cr = 2'b01,
        fg_coin_b_1co_4cr = 2'b10,
        fg_coin_a_1co_6cr = 2'b11
    } fg_coin_b_e;

    typedef enum logic {
        fg_shot_time_short  = 1'b0,
        fg_shot_time_long   = 1'b1
    } fg_shot_time_e;

    typedef enum logic {
        fg_bonus_holes_less  = 1'b0,
        fg_bonus_holes_more  = 1'b1
    } fg_bonus_holes_e;

    typedef enum logic[1:0] {
        fg_game_mode_freeze         = 2'b00,
        fg_game_mode_demo_on        = 2'b01,
        fg_game_mode_infinite_holes = 2'b10,
        fg_game_mode_demo_off       = 2'b11
    } fg_game_mode_e;

    typedef enum logic[1:0] {
        fg_playhole_5 = 2'b00,
        fg_playhole_4 = 2'b01,
        fg_playhoes_3 = 2'b10,
        fg_playhoes_2 = 2'b11
    } fg_play_holes_e;

    typedef enum logic {
        fg_allow_continue_no  = 1'b0,
        fg_allow_continue_yes = 1'b1
    } fg_allow_continue_e;

    typedef enum logic {
        fg_test_mode_off = 1'b0,
        fg_test_mode_on  = 1'b1
    } fg_test_mode_e;

    /*
		<dip bits="0"	  name="Language" ids="English, Japanese" values="1,0"/>
		<dip bits="1"     name="Flip Screen" ids="Off,On" values="1,0"/>
		<dip bits="2"     name="Controls" ids="Single,Dual" values="0,1"/>
		<dip bits="3"     name="Gameplay" ids="Basic Player,Avid Golfer" values="0,1"/>
		<dip bits="5,6"   name="Coin A" ids="4Co/1Cr,3Co/1Cr,2Co/1Cr,1Co/1Cr" values="0,1,2,3"/>
		<dip bits="7,8"   name="Coin B" ids="1Co/2Cr,1Co/3Cr,1Co/4Cr,1Co/6Cr" values="0,2,1,3"/>

		<!-- DSW2 -->
		<dip bits="8"     name="Shot Time" ids="Short (15 sec),Long (20sec)" values="0,1"/>
		<dip bits="9"     name="Bonus Holes" ids="More (Par 1,Birdie 2,Eagle 3),Less (Par 0,Birdie 1,Eagle 2)" values="1,0"/>
		<dip bits="10,11" name="Game Mode" ids="Demo Sounds Off,Demo Sounds On,Freeze,Infinite Holes (Cheat)" values="1,3,0,2"/>
		<dip bits="12,13" name="Play Holes" ids="2,3,4,5" values="3,2,1,0"/>
		<dip bits="14"    name="Allow Continue (Cheat)" ids="No,Yes" values="0,1"/>
        */

    typedef struct packed {
        fg_test_mode_e      test_mode;
        fg_allow_continue_e allow_continue;
        fg_play_holes_e     play_holes;
        fg_game_mode_e      game_mode;
        fg_bonus_holes_e    bonus_holes;
        fg_shot_time_e      shot_time;
        fg_coin_b_e         coin_b;
        fg_coin_a_e         coin_a;
        fg_gameplay_e       gameplay;
        fg_cabinet_e        cabinet;
        fg_flip_screen_e    flip_screen;
        fg_language_e       language;
    } dip_switch_fighting_golf_t;

    function automatic logic[15:0] dip_switch_fighting_golf_map(dip_switch_fighting_golf_t d);
        // these are already in order
        return d;
    endfunction

    typedef struct packed {
        logic [12:0] addr;
        logic [7:0]  data_out;
        logic [7:0]  data_in;
        logic        nCS;
        logic        nWE;
        logic        VDG;
        logic        VOE;
        logic        VRD;
    } side_ram_t;

    // highscore data is a 0xfe50 on the CPU side memory. To make
    // the mapping easier, use 0x1000fe50 as the load address for
    // the hiscore data.
    // This need to match data.json
    parameter pocket::slot_id_t     HISCORE_SLOT_ID = 2;
    parameter pocket::bridge_addr_t HISCORE_START   = 32'h1000fe50;
    parameter pocket::bridge_data_t HISCORE_SIZE    = 32'h72;
    parameter pocket::bridge_addr_t HISCORE_END     = HISCORE_START + HISCORE_SIZE - 1;

endpackage
