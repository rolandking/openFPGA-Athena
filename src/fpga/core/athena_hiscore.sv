`timescale 1ns/1ps

module athena_hiscore(
    bus_if                    bridge_hs,
    input logic               game_clk,
    input athena::side_ram_t  side_ram_monitor,
    output athena::side_ram_t side_ram_in,

    output logic              base_written_a,
    output logic [NUM_TESTS-1:0]     test_match_a
);

    // monitor writes to the first 2 and last 2 addresses
    typedef logic [10:0] ram_addr_t;
    typedef logic [7:0]  data_t;

    localparam int        NUM_TESTS = 5;
    localparam ram_addr_t ADDRESSES[NUM_TESTS] = '{11'h650, 11'h651, 11'h6bf, 11'h6c0, 11'h6c1};
    localparam data_t     DATA[NUM_TESTS]      = '{ 8'heb,   8'hf8,   8'h30,   8'h30,   8'hff };

    logic [NUM_TESTS-1:0] test_match = '0;

    generate
    genvar i;
        for( i = 0 ; i < NUM_TESTS ; i++ ) begin : gen_test
            always_ff @(posedge game_clk) begin
                if(
                    (ADDRESSES[i] == side_ram_monitor.addr[10:0])    &&
                    (DATA[i]      == side_ram_monitor.data_in) &&
                    ~side_ram_monitor.nCS                      &&
                    ~side_ram_monitor.nWE
                ) begin
                    test_match[i] <= '1;
                end
            end
        end
    endgenerate

    // asserts when all writes have been seen
    wire base_written = &test_match;

    always_comb begin
        side_ram_in = side_ram_monitor;
        base_written_a = base_written;
        test_match_a = test_match;
    end

endmodule
