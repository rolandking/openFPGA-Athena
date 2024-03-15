`timescale 1ns/1ps

module athena_dip(
    bus_if              bridge,
    output logic [15:0] dip_switches
);
    athena::dip_switch_t dip_switch = athena::DIP_SWITCH_DEFAULT;

    always_ff @(posedge bridge.clk) begin
        if(bridge.wr) begin
            dip_switch <= bridge.wr_data;
        end
    end

    always_comb begin
        dip_switches = athena::dip_switch_map(dip_switch);
    end

endmodule
