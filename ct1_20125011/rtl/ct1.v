//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Upcounter 1 (up1)
// Author: Karl Rinne
// Create Date: 27/05/2020
// Design Name: generic
// Revision: 1.0
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2001
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

`include "timing.v"

module ct1
(
    input wire                  clk,
    input wire                  reset,
    input wire					turbosim,
    input wire [1:0]            buttons,        // {L, R}
    input wire 					muxpb,
    output wire [7:0]           d7_cathodes_n,  // {DP,CG,CF,CE,CD,CC,CB,CA}
    output wire [7:0]           d7_anodes,
    output wire                 blink,
    output wire                 buzzer_p,
    output wire                 buzzer_n,
    output wire [15:0]          bcd,
    output wire [3:0]           fsm_state
);


    localparam  d7_space=8'b00000000;    // display character ' '
    localparam  d7_A=8'b01110111;    // display character 'A'
    localparam  d7_C=8'b00111001;    // display character 'C'
    localparam  d7_c=8'b01011000;    // display character 'c'
    localparam  d7_d=8'b01011110;    // display character 'd'
    localparam  d7_E=8'b01111001;    // display character 'E'
    localparam  d7_F=8'b01110001;    // display character 'F'
    localparam  d7_h=8'b01110100;    // display character 'h'
    localparam  d7_I=8'b00110000;    // display character 'I'
    localparam  d7_L=8'b00111000;    // display character 'L'
    localparam  d7_r=8'b01010000;    // display character 'r'
    localparam  d7_S=8'b01101101;    // display character 'S'
    localparam  d7_t=8'b01111000;    // display character 't'
    localparam  d7_U=8'b00111110;    // display character 'U'
    localparam  d7_y=8'b01101110;    // display character 'y'

    wire                        reset_s;        // synchronised reset signal
    wire                        clk_ev_1s;
    wire                        clk_ev_100us;
    wire						clk_ev_1ms;

    wire                        button_l;       // debounced
    wire                        button_r;       // debounced
	wire [7:0]					mbuttons;
    wire                        bcd_fs;
    wire [7:0]                  button_all;
    wire                        bcd_clear;
    wire                        bcd_fsm_en;
    wire                        beep;
    wire [15:0]                 bcdout;
    wire                        bcd_ini;
    wire                        set_fs;
    wire [79:0]                 d7_SetMode;

    wire [79:0]                 d7_content_selected;
    wire [79:0]                 d7_content0;
    wire [79:0]                 d7_content1;
    wire [79:0]                 d7_content2;
    wire [79:0]                 d7_content3;
    wire [79:0]                 d7_content4;
    wire [79:0]                 d7_content5;
    wire [79:0]                 d7_content6;
    wire [79:0]                 d7_content7;
    wire [79:0]                 d7_content8;
    wire [3:0]                  d7_content_sel;


    // Assign display contents (blink, mode, data)
    // "UL    "
    assign d7_content0={8'b0000_0000,8'b0000_0000, 16'h0, d7_U, d7_L, d7_space, d7_space, d7_space, d7_space};
    // "UL ECE"
    assign d7_content1={8'b0000_0000,8'b0000_0000, 16'h0, d7_U, d7_L, d7_space, d7_E,d7_C,d7_E};
    // "EE6621"
    assign d7_content2={8'b0000_0000,8'b0000_1111, 16'h0, d7_E,d7_E, 8'h6,8'h6,8'h2,8'h1};
    // "   ct1"
    assign d7_content3={8'b0000_0000,8'b0000_0001, 16'h0, d7_space, d7_space, d7_space, d7_c,d7_t,8'h1};
    
    // "Student ID"
    assign d7_content4={8'b0000_0000,8'b0011_1111, 16'h0, 8'h1,8'h2, 8'h5,8'h0,8'h1,8'h1};
    // "BCD Run"
    assign d7_content5={8'b0000_0000,8'b0000_1111, 16'h0, d7_c, d7_space, 4'h0,bcd[15:12],4'h0,bcd[11:8],4'h0,bcd[7:4],4'h0,bcd[3:0]};
    // Set mode shows
    assign d7_content6=d7_SetMode;
    // BCD
    assign d7_content7 = {8'b0000_0000,8'b0000_1111, 16'h0, d7_space, d7_space, 4'h0,bcd[15:12],4'h0,bcd[11:8],4'h0,bcd[7:4],4'h0,bcd[3:0]};
	//assign A number to BCD
	assign d7_content8 = {8'b0000_1111,8'b0000_1111, 16'h0, d7_space, d7_space, 4'h0,bcd[15:12],4'h0,bcd[11:8],4'h0,bcd[7:4],4'h0,bcd[3:0]};
	
	

    
    //assign bcd = bcdout;
    
    // Synchronise the incoming raw reset signal
    synchroniser_3s synchroniser_3s_reset
    (
        .clk(clk),
        .reset(1'b0),
        .en(1'b1),
        .in(reset),
        .out(reset_s)
    );

    // Instantiate a down counter to provide 1ms time base
    counter_down_rld #( .COUNT_MAX(99_999_999), .COUNT_MAX_TURBOSIM(99_999) ) counter_1s
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .rld(1'b0),
        .underflow(clk_ev_1s)
    );

    counter_down_rld #( .COUNT_MAX(99_999), .COUNT_MAX_TURBOSIM(99) ) counter_1ms
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .rld(1'b0),
        .underflow(clk_ev_1ms)
    );

    // Instantiate a down counter to provide 100us time base (for sampling of button, debounce)
    counter_down_rld #( .COUNT_MAX(9_999), .COUNT_MAX_TURBOSIM(9) ) counter_100us
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .rld(1'b0),
        .underflow(clk_ev_100us)
    );

    // Instantiate a display mux
    display_7s_mux display_7s_mux
    (
        .dis_content0(d7_content0),
        .dis_content1(d7_content1),
        .dis_content2(d7_content2),
        .dis_content3(d7_content3),
        .dis_content4(d7_content4),
        .dis_content5(d7_content5),
        .dis_content6(d7_content6),
        .dis_content7(d7_content7),
		.dis_content8(d7_content8),
        .dis_data(d7_content_selected),
        .sel(d7_content_sel)
    );

    // Instantiate a 7-segment display driver
    display_7s #( .PRESCALER_RLD(99_999), .BLINK_RLD(499) ) display_7s
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .en(1'b1),
        .dis_data(d7_content_selected[63:0]),
        .dis_mode(d7_content_selected[71:64]),
        .dis_blink(d7_content_selected[79:72]),
        .negate_a(1'b0),            // we're using non-negating external drivers for anodes (npn emitter follower)
        .cathodes_n(d7_cathodes_n),
        .anodes(d7_anodes),
        .blink(blink)
    );

    //Instantiate debounce for buttons[1] (left)
    debounce debounce_l
    (
        .clk(clk),
        .reset(reset_s),
        .en(clk_ev_100us),
        .signal_in(buttons[1]),
        .signal_debounced(button_l)
    );

    //Instantiate debounce for buttons[0] (right)
    debounce debounce_r
    (
        .clk(clk),
        .reset(reset_s),
        .en(clk_ev_100us),
        .signal_in(buttons[0]),
        .signal_debounced(button_r)
    );

    // Instantiate a buzzer (1.6kHz, 0.2s)
    buzzer #(.BUZZER_RLD(31_249), .BUZZER_DUR(299) ) buzzer
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .en_posedge(1'b0),
        .en(beep),
        .buzzer_p(buzzer_p),
        .buzzer_n(buzzer_n)
    );

    // Instantiate a 4-digit BCD counter
    bcd_counter_4d bcd_counter_4d
    (
        .clk(clk),
        .reset(reset_s),
        .en(clk_ev_1s&bcd_fsm_en),
        .clr(bcd_clear),
        .fs(bcd_fs),
        .bcd(bcd),
        .bcdin(bcdout)
    );

	// Instantiate the addition button signal.
    mbutton #(.MUX_NOB(8)) mbutton
    (
        .clk(clk),
        .reset(reset_s),
        .muxin(d7_anodes),
        .pbin(muxpb),
        .buttons(mbuttons)
    );

	//assign
	assign button_all = {mbuttons[5:0], button_l, button_r};

    // Instantiate reaction timer game's FSM
    fsm_game fsm_game
    (
        .clk(clk),
        .reset(reset_s),
        .timebase(clk_ev_1ms),
        .timebase_set(clk_ev_1s),
        .button(button_all),
        .dis_sel(d7_content_sel),
        .beep(beep),
        .reaction_counter_clr(bcd_clear),
        .reaction_counter_en(bcd_fsm_en),
        .reaction_counter_fs(bcd_fs),
        .bcdset(bcdout),
        .d7_SetMode(d7_SetMode),
        .fsm_state(fsm_state)
    );

endmodule
