//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Reaction Timer rt2 (targeting Digilent Cmod A7-x5T)
// Author: Karl Rinne
// Create Date: 27/05/2020
// Design Name: generic
// Revision: 1.1    21/07/21 AY2021-22 (change of IO mapping to cater for ee6621_ui02 daughter-board
// Revision: 1.0    20/07/20 AY2020-21
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2001
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

`include "timing.v"

module fpga_wrapper_ct1
(
    input wire                  clk_raw_in,
    input wire [1:0]            btn,    // where btn[0] is closer to the PMOD connector
    output wire [1:0]           led,
    output wire                 led0_b,
    output wire                 led0_g,
    output wire                 led0_r,
    output wire                 pio23,  // wired to buzzer_p
    input  wire                 pio22,  // reserved for ee6621_ui01 pb
    output wire                 pio14,  // wired to anode base an5
    output wire                 pio13,  // wired to anode base an4
    output wire                 pio12,  // wired to anode base an3
    output wire                 pio11,  // wired to anode base an2
    output wire                 pio10,  // wired to anode base an1
    output wire                 pio9,   // wired to anode base an0
    output wire                 pio8,   // wired to cathode dp
    output wire                 pio7,   // wired to cathode g
    output wire                 pio6,   // wired to cathode f
    output wire                 pio5,   // wired to cathode e
    output wire                 pio4,   // wired to cathode d
    output wire                 pio3,   // wired to cathode c
    output wire                 pio2,   // wired to cathode b
    output wire                 pio1    // wired to cathode a
);

    // internal clock signals
    wire    clk_100MHz;
    wire    clk_locked;

    // internal signals, not brought out
    wire    an7, an6;

    // Turn off RGB LED (cathodes are driven by i/o)
    assign  led0_b=1;
    assign  led0_g=1;
    assign  led0_r=1;

    // Turn off unused green LEDs (anodes are driven by i/o)
    assign  led[1]=0;

    // Instantiate clock generator
    clkgen_cmod_a7 clkgen_cmod_a7
    (
        .clk_raw_in(clk_raw_in),
        .reset_async(1'b0),
        .clk_200MHz(),
        .clk_100MHz(clk_100MHz),
        .clk_50MHz(),
        .clk_20MHz(),
        .clk_12MHz(),
        .clk_10MHz(),
        .clk_5MHz(),
        .clk_locked(clk_locked)
    );

    // Instantiate up1
    ct1 ct1
    (
        .clk(clk_100MHz),
        .reset(btn[0]&btn[1]),
        .turbosim(1'b0),
        .buttons({btn}),
        .d7_cathodes_n({pio8,pio7,pio6,pio5,pio4,pio3,pio2,pio1}),
        .d7_anodes({an7, an6, pio14,pio13,pio12,pio11,pio10,pio9}),
        .muxpb(pio22),
        .blink(led[0]),
        .buzzer_p(pio23),
        .buzzer_n(),
        .bcd(),
        .fsm_state()
    );

endmodule
