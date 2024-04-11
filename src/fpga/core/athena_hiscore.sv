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
    input logic                     pause_cpu,

    input logic                     is_fighting_golf
);

    localparam int NUM_TESTS = 5;
    typedef struct {
        ram_addr_t            ADDRESSES[NUM_TESTS];
        data_t                DATA[NUM_TESTS];
        pocket::bridge_data_t SIZE;
        pocket::bridge_addr_t OFFSET;
    } hs_info_t;

    // monitor writes to the first 2 and last 2 addresses
    typedef logic [10:0] ram_addr_t;
    typedef logic [7:0]  data_t;

    localparam hs_info_t HS_INFO[2] = '{
        '{
            '{11'h650, 11'h651, 11'h6bf, 11'h6c0, 11'h6c1},
            '{ 8'heb,   8'hf8,   8'h30,   8'h30,   8'hff },
            32'h72,
            32'h650
        },
        '{
            '{11'h770, 11'h771, 11'h7bd, 11'h7be, 11'h7bf},
            '{ 8'h53,   8'h4e,   8'h2e,   8'h2e,   8'h14 },
            32'h50,
            32'h770
        }
    };

    hs_info_t hs_info;
    always_ff @(posedge bridge_hs.clk) begin
        hs_info <= HS_INFO[ is_fighting_golf ? 1'b1 : 1'b0 ];
    end

    logic [NUM_TESTS-1:0] test_match = '0;

    generate
    genvar i;
        for( i = 0 ; i < NUM_TESTS ; i++ ) begin : gen_test
            always_ff @(posedge game_clk) begin
                if(
                    (hs_info.ADDRESSES[i] == side_ram_monitor.addr[10:0])    &&
                    (hs_info.DATA[i]      == side_ram_monitor.data_in) &&
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
        .SLOT_ID    (athena::HISCORE_SLOT_ID)
    ) find_and_replace (
        .bridge_dataslot_in,
        .bridge_dataslot_out,
        .host_dataslot_request_write,

        .slot_size                    (hs_info.SIZE),

        .slot_base_found,
        .slot_size_zero
    );

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
        core_dataslot_read.param.slot_id     = athena::HISCORE_SLOT_ID;
        core_dataslot_read.param.slot_offset = '0;
        core_dataslot_read.param.bridge_addr = athena::HISCORE_START;
        core_dataslot_read.param.length      = hs_info.SIZE;
        core_dataslot_read.valid             = (state == WRITING);

        // the CPU is already paused during the final hi-score read
        // but we need to hold it to control the lines while the
        // hi-score table is being written
        hs_pause_req                         = (state == WRITING);
    end

    // read and write for the HISCORE data
    bus_if#(
        .addr_width  (32),
        .data_width  (32)
    ) hs_cdc (.clk(game_clk));

    bridge_cdc mem_cdc(
        .in  (bridge_hs),
        .out (hs_cdc)
    );

    bus_if#(
        .addr_width  (13),
        .data_width  (8)
    ) mem (.clk(game_clk));

    bridge_to_bytes to_mem (
        .bridge  (hs_cdc),
        .mem
    );

    // when the CPU is paused we connect the memory system to the
    // bridge, else we loop it back
    always_comb begin
        mem.rd_data = side_ram_monitor.data_out;
        if(pause_cpu) begin
            side_ram_in.addr     = mem.addr + hs_info.OFFSET;
            side_ram_in.data_in  = mem.wr_data;
            side_ram_in.nCS      = '0;
            side_ram_in.nWE      = ~mem.wr;
            side_ram_in.VDG      = '0;
            side_ram_in.VRD      = mem.wr;
            side_ram_in.VOE      = '0;
            side_ram_in.data_out = '0;
        end else begin
            side_ram_in = side_ram_monitor;
        end
    end

    always_ff @(posedge mem.clk) begin
        mem.rd_data_valid <= mem.rd;
    end



endmodule
