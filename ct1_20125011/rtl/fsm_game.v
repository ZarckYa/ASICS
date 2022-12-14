//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: FSM reaction timer game
// Author: Karl Rinne
// Create Date: 31/05/2020
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

module fsm_game
#(
    parameter           WAIT_VLONG=9999,
    parameter           WAIT_LONG=1999,
    parameter           WAIT_MEDIUM=999,
    parameter           WAIT_SHORT=199,
    parameter           RND_MIN=200,
    parameter           RND_MAX=2999
)
(
    input wire          clk,                // clock input (rising edge)
    input wire          reset,              // reset input (synchronous)
    input wire          timebase,           // clock time base event (1ms expected)
    input wire          timebase_set,
    input wire [7:0]    button,             // button to operate game (starts game sequence, stops reaction timer)
    output reg [3:0]    dis_sel,            // display select driving display mux
    output reg          beep,
    output reg          reaction_counter_clr,
    output reg          reaction_counter_en,
    input wire          reaction_counter_fs,
    output reg [15:0]	bcdset,
    output reg [79:0]	d7_SetMode,	
    output wire [3:0]   fsm_state
);

`include "wordlength.v"
`include "fsm_game_states.v"

reg [S_NOB-1:0]         state;
reg [S_NOB-1:0]         next_state;

// Definitions of display strings
localparam              D_UL=0;
localparam              D_ECE=1;
localparam              D_MODULE=2;
localparam              D_LAB=3;
localparam              D_STUID=4;
localparam              D_BCDRUN=5;
localparam              D_SETNUM=6;
localparam              D_BCD=7;
localparam              D_BCDALARM=8;

// FSM timing
reg [wordlength(WAIT_VLONG)-1:0] counter;    // counter vector
reg [wordlength(WAIT_VLONG)-1:0] counter_load_value;
reg                     counter_load;       // counter load instruction
wire                    counter_zero;       // counter zero flag

reg [wordlength(WAIT_VLONG)-1:0] rnd_counter;    // pseudo-random up counter
wire                    rnd_counter_max;
reg                     counter_load_rnd;

// button logging (for the detection of cheating during state S_STEADY)
reg                     button_prev;
reg                     button_logged;
reg                     button_logged_clr;
reg						flag;

// make FSM state accessible
assign fsm_state=state;


// general timing
always @ (posedge clk) begin
    if (reset) begin
        counter<=0;
    end
    else begin
        if (counter_load) begin
            counter<=counter_load_value;
        end else begin
            if (counter_load_rnd) begin
                counter<=rnd_counter;
            end else begin
                if ( (~counter_zero) & timebase) begin
                    counter<=counter-1'b1;
                end
            end
        end
    end
end
assign counter_zero=(counter==0);

// counter for generation of pseudo-random timing
always @ (posedge clk) begin
    if (reset) begin
        rnd_counter<=RND_MIN;
    end
    else begin
        if (timebase) begin
            if (rnd_counter_max) begin
                rnd_counter<=RND_MIN;
            end else begin
                rnd_counter<=rnd_counter+1;
            end
        end
    end
end
assign rnd_counter_max=(rnd_counter==RND_MAX);

// log button turn-on activity
always @ (posedge clk) begin
    if ( reset ) begin
        button_logged<=0;
    end
    else begin
        if (button_logged_clr) begin
            button_logged<=0; button_prev<=button;
        end else begin
            if ( button & (~button_prev) ) begin
                // log a button pressed event
                button_logged<=1;
            end
            button_prev<=button;
        end
    end
end


// Management of state register:
// Clock-synchronous progression from current state to next state. Also define reset state.
always @(posedge clk) begin
    if (reset) begin 
        state<=S_RESET;
    end else begin
        state<=next_state;
    end
end

// Next-state and output logic. Purely combinational.
always @(*) begin
    // define default next state, and default outputs
    next_state=state;
    reaction_counter_clr=0; reaction_counter_en=0; 
    dis_sel=D_UL; beep=0;
    counter_load=0; counter_load_value=WAIT_MEDIUM; counter_load_rnd=0;
    button_logged_clr=0;
    case (state)
        S_RESET: begin
            counter_load=1; counter_load_value=WAIT_MEDIUM;
            next_state=S_SHOW_UL;
        end
     // SHOW UL    
        S_SHOW_UL: begin
            dis_sel=D_UL;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_ECE;
            end
        end
      //SHOW ECE  
        S_SHOW_ECE: begin
            dis_sel=D_ECE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_MODULE;
            end
        end
       //SHOW EE66621 
        S_SHOW_MODULE: begin
            dis_sel=D_MODULE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_DESIGN;
            end
        end
        //SHOW ct1
        S_SHOW_DESIGN: begin
            dis_sel=D_LAB;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_STUID;
            end
        end
        //SHOW STUDENT ID
        S_STUID: begin
            dis_sel=D_STUID;
            if ( counter_zero ) begin
                counter_load_rnd=1; counter_load_value=WAIT_LONG;
                next_state=S_INITIAL;
            end
        end
        
        //Initial the timer start number to 0325 
        S_INITIAL: begin
			bcdset[15:12] = 4'd0;
			bcdset[11:8] = 4'd3;
			bcdset[7:4] = 4'd2;
			bcdset[3:0] = 4'd5;
			d7_SetMode = {8'b0000_0000,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM; 
			reaction_counter_clr=1;
			if (counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED; 
			end
		end
        
        
       /*S_SET_D1: begin
			d7_SetMode={8'b0000_1000,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( counter_zero && button[5] ) begin
				bcdset[15:12] = bcdset[15:12] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[15:12] > 4'd9) begin
					bcdset[15:12] = 4'd0;
				end
			end else if ( counter_zero && button[4] ) begin
				bcdset[15:12] = bcdset[15:12] - 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[15:12] < 4'd0) begin
					bcdset[15:12] = 4'd9;
				end
			end else if ( button[3] & counter_zero) begin
					counter_load=1; counter_load_value=WAIT_SHORT;
					next_state = S_SET_D4;
				end else if ( button[2] & counter_zero) begin
					counter_load=1; counter_load_value=WAIT_SHORT;
					next_state = S_SET_D2;
				end else if ( button[7] & counter_zero) begin
					counter_load=1; counter_load_value=WAIT_SHORT;
					next_state = S_STOPPED;
				end else if ( button[6] & counter_zero) begin
					reaction_counter_clr=1;
					counter_load=1; counter_load_value=WAIT_SHORT;
					next_state = S_STOPPED;
				end
		end*/
		
		// Adjust first digit
		// Muxed buttons added in the block
		S_SET_D1: begin
			d7_SetMode={8'b0000_1000,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( counter_zero && button[5] ) begin
				bcdset[15:12] = bcdset[15:12] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[15:12] > 4'd9) begin
					bcdset[15:12] = 4'd0;
				end
			end 
			if ( counter_zero && button[4] ) begin
				bcdset[15:12] = bcdset[15:12] - 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[15:12] < 4'd0) begin
					bcdset[15:12] = 4'd9;
				end
			end 
			if ( button[3] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D4;
			end 
			if ( button[2] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D2;
			end 
			if ( button[7] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end 
			if ( button[6] & counter_zero) begin
				reaction_counter_clr=1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end
		end
	
		
		/*S_SET_D2: begin
			d7_SetMode={8'b0000_0100,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( button[5] & counter_zero) begin
				bcdset[11:8] = bcdset[11:8] + 1'd1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[11:8] > 4'd9) begin
					bcdset[11:8] = 4'd0;
				end
			end else if ( button[4] & counter_zero) begin
				bcdset[11:8] = bcdset[11:8] - 1'b1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[11:8] < 4'd0) begin
					bcdset[11:8] = 4'd9;
				end 
			end else if ( button[3] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D1;
					end else if ( button[2] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D3;
					end else if ( button[7] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end else if ( button[6] & counter_zero) begin
						reaction_counter_clr=1;
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end
		end*/
			
		// Adjust second blocks	
		S_SET_D2: begin
			d7_SetMode={8'b0000_0100,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( button[5] & counter_zero) begin
				bcdset[11:8] = bcdset[11:8] + 1'd1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[11:8] > 4'd9) begin
					bcdset[11:8] = 4'd0;
				end
			end 
			if ( button[4] & counter_zero) begin
				bcdset[11:8] = bcdset[11:8] - 1'b1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[11:8] < 4'd0) begin
					bcdset[11:8] = 4'd9;
				end 
			end 
			if ( button[3] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D1;
			end 
			if ( button[2] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D3;
			end
			if ( button[7] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end
			if ( button[6] & counter_zero) begin
				reaction_counter_clr=1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end
		end	
			
			
			
		/*S_SET_D3: begin
			d7_SetMode={8'b0000_0010,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( button[5] & counter_zero) begin
				bcdset[7:4] = bcdset[7:4] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[7:4] > 4'd9) begin
					bcdset[7:4] = 4'd0;
				end
			end else if ( button[4] & counter_zero) begin
				bcdset[7:4] = bcdset[7:4] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[7:4] < 4'd0) begin
					bcdset[7:4] = 4'd9;
				end
			end else if ( button[3] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D2;
					end else if ( button[2] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D4;
					end else if ( button[7] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end else if ( button[6] & counter_zero) begin
						reaction_counter_clr=1;
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end
        end*/
        
        // The third blocks
        S_SET_D3: begin
			d7_SetMode={8'b0000_0010,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			if ( button[5] & counter_zero) begin
				bcdset[7:4] = bcdset[7:4] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[7:4] > 4'd9) begin
					bcdset[7:4] = 4'd0;
				end
			end 
			if ( button[4] & counter_zero) begin
				bcdset[7:4] = bcdset[7:4] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[7:4] < 4'd0) begin
					bcdset[7:4] = 4'd9;
				end
			end 
			if ( button[3] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D2;
			end 
			if ( button[2] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D4;
			end 
			if ( button[7] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end 
			if ( button[6] & counter_zero) begin
				reaction_counter_clr=1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end
        end
        
        
        
        
        /*S_SET_D4: begin
			d7_SetMode={8'b0000_0001,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			//reaction_counter_clr = 1;
			if ( button[5] & counter_zero) begin
				bcdset[3:0] = bcdset[3:0] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[3:0] > 4'd9) begin
					bcdset[3:0] = 4'd0;
				end
			end else if ( button[4] & counter_zero) begin
				bcdset[3:0] = bcdset[3:0] - 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[3:0] < 4'd0) begin
					bcdset[3:0] = 4'd9;
				end
			end else if ( button[3] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D3;
					end else if ( button[2] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_SET_D1;
					end else if ( button[7] & counter_zero) begin
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end else if ( button[6] & counter_zero) begin
						reaction_counter_clr=1;
						counter_load=1; counter_load_value=WAIT_SHORT;
						next_state = S_STOPPED;
					end
        end*/
        
        //The last blocks
        S_SET_D4: begin
			d7_SetMode={8'b0000_0001,8'b0000_1111, 16'h0, 8'b00000000, 8'b00000000, 4'h0,bcdset[15:12],4'h0,bcdset[11:8],4'h0,bcdset[7:4],4'h0,bcdset[3:0]};
			dis_sel=D_SETNUM;
			//reaction_counter_clr = 1;
			if ( button[5] & counter_zero) begin
				bcdset[3:0] = bcdset[3:0] + 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[3:0] > 4'd9) begin
					bcdset[3:0] = 4'd0;
				end
			end 
			if ( button[4] & counter_zero) begin
				bcdset[3:0] = bcdset[3:0] - 1'b1; 
				counter_load=1; counter_load_value=WAIT_SHORT;
				if (bcdset[3:0] < 4'd0) begin
					bcdset[3:0] = 4'd9;
				end
			end 
			if ( button[3] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D3;
			end 
			if ( button[2] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_SET_D1;
			end 
			if ( button[7] & counter_zero) begin
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end 
			if ( button[6] & counter_zero) begin
				reaction_counter_clr=1;
				counter_load=1; counter_load_value=WAIT_SHORT;
				next_state = S_STOPPED;
			end
        end
        
        
        // Timer running block
        S_RUN: begin
            dis_sel=D_BCDRUN; reaction_counter_en=1;
            if ( button[1] & counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_STOPPED; 
            end 
            if ( reaction_counter_fs ) begin
				next_state = S_ALARM; counter_load = 1; counter_load_value=WAIT_VLONG;
			end
        end
        
        //Stop block, any block can enter stopped
        S_STOPPED: begin
            dis_sel=D_BCD;
            if ( counter_zero & button[1] ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_RUN; 
            end else if ( counter_zero & button[0] ) begin
				counter_load=1; counter_load_value=WAIT_LONG;
				next_state = S_SET_D1;
				end 	
        end
        //When timer reach to 0000, the alarm is running
        S_ALARM: begin
			dis_sel=D_BCDALARM; beep = 1;
			if ( button[1]| button[0]) begin
				next_state = S_STOPPED; reaction_counter_clr=1; beep = 0; 
				counter_load = 1; counter_load_value=WAIT_SHORT;
				end else if( counter_zero ) begin
					next_state = S_STOPPED; reaction_counter_clr=1;beep = 0;
			    end
		end
        
        default: begin
            next_state=S_RESET;	    // unexpected, but best to handle this event gracefully (e.g. single event upsets SEU's)
        end
      endcase
end

endmodule
