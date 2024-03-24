package athena;

    typedef enum logic {
        cabinet_uprights = 1'b0,
        cabinet_cocktail = 1'b1
    } cabinet_e;

    typedef enum logic {
        lives_5          = 1'b0,
        lives_3          = 1'b1
    } lives_e;

    typedef enum logic[1:0]{
        coin_a_4co_1cr = 2'b00,
        coin_a_3co_1cr = 2'b01,
        coin_a_2co_1cr = 2'b10,
        coin_a_1co_1cr = 2'b11
    } coin_a_e;

    typedef enum logic[1:0]{
        coin_b_1co_2cr = 2'b00,
        coin_b_1co_3cr = 2'b01,
        coin_b_1co_4cr = 2'b10,
        coin_a_1co_6cr = 2'b11
    } coin_b_e;

    typedef enum logic[1:0]{
        difficulty_hardest = 2'b00,
        difficulty_hard    = 2'b01,
        difficulty_normal  = 2'b10,
        difficulty_easy    = 2'b11
    } difficulty_e;

    typedef enum logic {
        demo_sounds_on     = 1'b0,
        demo_sounds_off    = 1'b1
    } demo_sounds_e;

    typedef enum logic {
        freeze_on          = 1'b0,
        freeze_off         = 1'b1
    } freeze_e;

    typedef enum logic[2:0] {
        bonus_life_none        = 3'b000,
        bonus_life_100_200     = 3'b010,
        bonus_life_60_120      = 3'b100,
        bonus_life_50_100      = 3'b110,
        bonus_life_100_200_200 = 3'b011,
        bonus_life_60_120_120  = 3'b101,
        bonus_life_50_100_100  = 3'b111
    } bonus_life_e;

    typedef enum logic {
        energy_14 = 1'b0,
        energy_12 = 1'b1
    } energy_e;

    typedef struct packed {
        energy_e       energy;
        bonus_life_e   bonus_life;
        freeze_e       freeze;
        demo_sounds_e  demo_sounds;
        difficulty_e   difficulty;
        coin_b_e       coin_b;
        coin_a_e       coin_a;
        lives_e        lives;
        cabinet_e      cabinet;
    } dip_switch_t;

    function automatic logic[15:0] dip_switch_map(dip_switch_t d);
        return {
            d.energy,     1'b0, d.bonus_life[1:0],            1'b1, d.demo_sounds, d.difficulty,
            d.coin_b, d.coin_a, d.lives,           d.bonus_life[0], d.cabinet,             1'b0
        };
    endfunction

    function automatic dip_switch_t dip_switch_unmap(logic[15:0] l);
        dip_switch_t d;
        logic _d1, _d2;
        {
            d.energy,      _d1, d.bonus_life[1:0], d.freeze,        d.demo_sounds, d.difficulty,
            d.coin_b, d.coin_a, d.lives,           d.bonus_life[0], d.cabinet,              _d1
        } = l;

        return d;
    endfunction

    parameter dip_switch_t DIP_SWITCH_DEFAULT = '{
        energy      : energy_12,
        bonus_life  : bonus_life_100_200,
        freeze      : freeze_off,
        demo_sounds : demo_sounds_on,
        difficulty  : difficulty_normal,
        coin_b      : coin_b_1co_2cr,
        coin_a      : coin_a_1co_1cr,
        lives       : lives_5,
        cabinet     : cabinet_cocktail
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

endpackage
