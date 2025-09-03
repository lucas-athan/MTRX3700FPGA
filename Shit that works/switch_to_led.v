module switch_to_led (
    input wire [17:0] switches, // 18-bit input for switches
    output wire [17:0] leds      // 18-bit output for LEDs
);

    // This is a direct assignment.
    // It means the state of each LED will directly follow the state of its corresponding switch.
    assign leds = switches;

endmodule