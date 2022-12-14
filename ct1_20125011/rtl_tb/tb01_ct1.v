//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 rt2. Test bench focusing on the FSM.
// Author: Karl Rinne
// Create Date: 23/06/2020
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

module tb01_ct1;

    reg         clk;
    reg         reset;
    reg [1:0]   buttons;            // {L,R}
    reg		    muxpb;
    // 7-segment display
    wire [7:0]  d7_cathodes_n;
    wire [7:0]  d7_anodes;
    wire [15:0] bcd;
    wire [3:0]  fsm_state;
    wire        blink;
    wire        buzzer_p;
    wire        buzzer_n;


	// tb general purpose integer variables
	integer		i0, i1;
    integer     error_counter;

    // definition of FSM states
    `include "fsm_game_states.v"

    // Generate 100MHz clock signal (Nexys4 uses a 100MHz clock oscillator)
    initial begin
        clk = 0;                    // Signal clk starts at 0.
        #5;                         // Wait for 5ns so that subsequent active (rising) clock edges occur at multiples of 10ns (easier to read).
        forever #5 clk=~clk;        // First positive clock edge will occur at 10ns.
    end

    // Generate reset signal
    initial begin
        reset=1;                    // Assert reset at time 0, wait for 6 clk edges, then de-assert reset
        for(i0=0;i0<6;i0=i0+1) begin
            @(posedge clk);
        end
        #2; reset=0;
    end

    // Take game FSM through some key operations, and check response
    initial begin
        error_counter=0;
        $strobe("========================================================");
        $strobe("Launch TEST 1 (BCD Full-Scale)");
        buttons=2'b00;  // L: start. R: set
        wait (fsm_state==S_INITIAL)
        #5
        buttons=2'b10;  // L: start. R: set
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_RUN)
        #5
        buttons=2'b00;  // L: start. R: set
        $strobe("Sim Info: Button released at %0t.",$time);
        wait (fsm_state==S_STOPPED)
        #10
        $strobe("Sim Info: BCD shows %04h.",bcd);
        if (fsm_state==S_ALARM)begin
            $strobe("PASS: TEST 1");
            $strobe("========================================================");
        end else begin
            $strobe("FAIL: TEST 1");
            $strobe("========================================================");
            error_counter=error_counter+1;
        end

        $strobe();
        $strobe("========================================================");
        $strobe("Launch TEST 2 (Set other numbers)");
        #5
        buttons=2'b00;  // L: start. R: set
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_INITIAL)
        /*#5
        buttons=2'b01;  // L: start. R: set
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_SET_D1)
        #5
        muxpb=d7_anodes[0];  // d7_anodes[4]=ok
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_SET_D2)
        #5
        muxpb=d7_anodes[0];  // d7_anodes[4]=ok
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_SET_D3)
        #5
        muxpb=d7_anodes[0];  // d7_anodes[4]=ok
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_SET_D4)
        #5
        muxpb=d7_anodes[4];  // d7_anodes[4]=ok
        $strobe("Sim Info: Button pressed at %0t.",$time);
        //@ (fsm_state)*/
        #5
        buttons=2'b10;  // L: start. R: set
        $strobe("Sim Info: Button pressed at %0t.",$time);
        wait (fsm_state==S_RUN)
        #5
        buttons=2'b00;  // L: start. R: set
        $strobe("Sim Info: Button released at %0t.",$time);
        wait (fsm_state==S_STOPPED)
        #10
        $strobe("Sim Info: BCD shows %04h.",bcd);
        if (fsm_state==S_ALARM) begin
            $strobe("PASS: TEST 2");
            $strobe("========================================================");
        end else begin
            $strobe("FAIL: TEST 2");
            $strobe("========================================================");
            error_counter=error_counter+1;
        end

        

        $strobe();
        $strobe("========================================================");
        $strobe("Sim Info: Simulation finished normally with %0d error(s) at time %0t",error_counter,$time);
        $strobe("========================================================");

        #10 $finish;
    end

    //1 FSM report state
    always @(fsm_state) begin
        case ( fsm_state )
            S_SHOW_UL:
                $strobe("Sim Info: State S_SHOW_UL      entered at %0t.",$time);
            S_SHOW_ECE:
                $strobe("Sim Info: State S_SHOW_ECE     entered at %0t.",$time);
            S_SHOW_MODULE:
                $strobe("Sim Info: State S_SHOW_MODULE  entered at %0t.",$time);
            S_SHOW_DESIGN:
                $strobe("Sim Info: State S_SHOW_DESIGN  entered at %0t.",$time);
            S_STUID:
                $strobe("Sim Info: State S_STUID        entered at %0t.",$time);
            S_INITIAL:
                $strobe("Sim Info: State S_INITIAL       entered at %0t.",$time);
            S_SET_D1:
                $strobe("Sim Info: State S_SET_D1         entered at %0t.",$time);
            S_SET_D2:
                $strobe("Sim Info: State S_SET_D2         entered at %0t.",$time);
            S_SET_D3:
                $strobe("Sim Info: State S_SET_D3         entered at %0t.",$time);
            S_SET_D4:
                $strobe("Sim Info: State S_SET_D4         entered at %0t.",$time);
            S_RUN:
                $strobe("Sim Info: State S_RUN          entered at %0t.",$time);
            S_STOPPED:
                $strobe("Sim Info: State S_STOPPED      entered at %0t.",$time);
            S_ALARM:
                $strobe("Sim Info: State S_ALARM        entered at %0t.",$time);
            S_RESET:
                $strobe("Sim Info: State S_RESET        entered at %0t.",$time);
            default:
                $strobe("Sim Warning: State 0x%hh entered at %0t.",fsm_state,$time);
        endcase
    end

    // 1Instantiate the Unit Under Test (UUT) with turbosim asserted, for much increased simulation speed
    ct1 ct1
    (
        .clk(clk), 
        .reset(reset),
        .turbosim(1'b1),
        .buttons(buttons),
        .d7_cathodes_n(d7_cathodes_n),
        .d7_anodes(d7_anodes),
        .muxpb(muxpb),
        .blink(blink),
        .buzzer_p(buzzer_p),
        .buzzer_n(buzzer_n),
        .bcd(bcd),
        .fsm_state(fsm_state)
    );

    // Generate simulation output (to screen)
    initial begin
        // Set the format used by the %t text format specifier. unit/precision/"suffix"/min_field_width
        // $timeformat(-9, 1, " ns", 12);
        $timeformat(-3, 3, " ms", 12);
        // $timeformat(-6, 3, " us", 12);
        $strobe("Sim Info: Welcome to EE6621 RT2 (functional). Module %m. Starting simulation at time %0t.",$time);
    end

    // Good practice: Set a hard-stop simulation time (in case simulation runs into no other $finish system call prior to this)
    initial begin
        #1_000_000_000      // define hard-stop time for simulation
        $strobe("Sim Info: Simulation hard-stopped at time %0t",$time);
        $finish;
    end

  // Generate output data for visual inspection (required for Icarus compiler/simulator and GtkWave graphical tool)
    //initial begin
        //$dumpfile("tb01_rt2.lxt2");
        //$dumpvars(0,tb01_rt2);
    //end

endmodule
