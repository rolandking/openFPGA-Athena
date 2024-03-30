`timescale 1ns/1ps

module athena_hiscore(
    bus_if                          bridge_hs,
    input logic                     game_clk,
    input athena::side_ram_t        side_ram_monitor,
    output athena::side_ram_t       side_ram_in,

    bus_if                          bridge_dataslot_in,
    bus_if                          bridge_dataslot_out,
    host_dataslot_request_write_if  host_dataslot_request_write,

    core_dataslot_read_if           core_dataslot_read,

    output logic                    hs_pause_req,
    input logic                     pause_cpu
);

    // monitor writes to the first 2 and last 2 addresses
    typedef logic [10:0] ram_addr_t;
    typedef logic [7:0]  data_t;

    localparam int NUM_TESTS                   = 5;
    localparam ram_addr_t ADDRESSES[NUM_TESTS] = '{11'h650, 11'h651, 11'h6bf, 11'h6c0, 11'h6c1};
    localparam data_t DATA[NUM_TESTS]          = '{ 8'heb,   8'hf8,   8'h30,   8'h30,   8'hff };
    localparam pocket::slot_id_t SLOT_ID       = 2;
    localparam pocket::bridge_data_t SLOT_SIZE = 16'h72;
    localparam pocket::bridge_addr_t SLOT_ADDR = 32'h10000000;

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
    // FIXME: should CDC this
    wire base_written = &test_match;

    logic                 slot_base_found;
    logic                 slot_size_zero;

    bridge_dataslot_find_and_replace#(
        .SLOT_ID    (SLOT_ID),
        .SLOT_SIZE  (SLOT_SIZE)
    ) find_and_replace (
        .bridge_dataslot_in,
        .bridge_dataslot_out,
        .host_dataslot_request_write,

        .slot_base_found,
        .slot_size_zero
    );

    always_comb begin
        side_ram_in    = side_ram_monitor;
    end

    typedef enum logic[1:0] {
        WAITING = 2'b00,
        WRITING = 2'b01,
        DONE    = 2'b10
    } state_e;

    state_e state = WAITING;

    always @(posedge bridge_hs.clk) begin
        case(state)
            WAITING: begin
                if(slot_base_found && base_written) begin
                    if(!slot_size_zero) begin
                        state <= WRITING;
                    end else begin
                        state <= DONE;
                    end
                end
            end

            WRITING: begin
                if(core_dataslot_read.done) begin
                    state <= DONE;
                end
            end

            DONE: begin
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        core_dataslot_read.param.slot_id     = SLOT_ID;
        core_dataslot_read.param.slot_offset = '0;
        core_dataslot_read.param.bridge_addr = SLOT_ADDR;
        core_dataslot_read.param.length      = SLOT_SIZE;
        core_dataslot_read.valid             = (state == WRITING);

        // the CPU is already paused during the final hi-score read
        // but we need to hold it to control the lines while the
        // hi-score table is being written
        hs_pause_req                         = (state == WRITING);
    end

endmodule
