`timescale 1ns/1ps

module athena_hiscore(
    bus_if                          bridge_hs,
    input logic                     game_clk,
    input athena::side_ram_t        side_ram_monitor,
    output athena::side_ram_t       side_ram_in,

    bus_if                          bridge_dataslot_in,
    bus_if                          bridge_dataslot_out,
    host_dataslot_request_write_if  host_dataslot_request_write
);

    // monitor writes to the first 2 and last 2 addresses
    typedef logic [10:0] ram_addr_t;
    typedef logic [7:0]  data_t;

    localparam int        NUM_TESTS = 5;
    localparam ram_addr_t ADDRESSES[NUM_TESTS] = '{11'h650, 11'h651, 11'h6bf, 11'h6c0, 11'h6c1};
    localparam data_t     DATA[NUM_TESTS]      = '{ 8'heb,   8'hf8,   8'h30,   8'h30,   8'hff };
    localparam pocket::slot_id_t SLOT_ID       = 2;
    localparam pocket::bridge_data_t SLOT_SIZE = 16'h72;

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

    pocket::bridge_addr_t slot_base_address;
    logic                 slot_base_found;
    logic                 slot_size_zero;
    bridge_dataslot_finder#(
        .SLOT_ID  (SLOT_ID)
    ) dataslot_finder (
        .bridge_dataslot                (bridge_dataslot_in),
        .host_dataslot_request_write,

        .slot_base_address,
        .slot_base_found,
        .slot_size_zero
    );

    always_comb begin
        side_ram_in    = side_ram_monitor;
    end

    bridge_pkg::dataslot_odd_t odd_slot;
    always_comb begin
        odd_slot                           = bridge_dataslot_in.rd_data;
        odd_slot.size_lower                = SLOT_SIZE;

        bridge_dataslot_out.addr           = bridge_dataslot_in.addr;
        bridge_dataslot_out.wr             = bridge_dataslot_in.wr;
        bridge_dataslot_out.wr_data        = bridge_dataslot_in.wr_data;
        bridge_dataslot_out.rd             = bridge_dataslot_in.rd;

        bridge_dataslot_in.rd_data_valid   = bridge_dataslot_out.rd_data_valid;
        bridge_dataslot_in.rd_data         = (bridge_dataslot_in.addr == {slot_base_address[31:3],3'b100}) ?
            odd_slot :
            bridge_dataslot_out.rd_data;
    end

endmodule
