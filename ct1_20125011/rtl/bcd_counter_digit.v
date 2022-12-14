//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: Loadable single-digit BCD up/down counter
// Author: Karl Rinne
// Create Date: 29/05/2020
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

module bcd_counter_digit
(
    input wire          clk,                // clock input
    input wire          reset,              // reset input (synchronous)
    input wire          up,                 // instruction to count up (or down when de-asserted)
    input wire          en,                 // counting enabled
    input wire          load,               // load instruction
    input wire [3:0]    value,              // load value, also post-reset value
    output reg [3:0]    bcd,                // bcd output value
    output wire         co,                 // carry out (or borrow out)
    output wire         fs                  // full scale flag
);

wire                    bcd_max, bcd_min;

always @ (posedge clk) begin
    if (reset) begin
        bcd<=value;
    end
    else begin
        if (load) begin
            // load takes priority over count
            bcd<=value;
        end else begin
            if (en) begin
                if (up) begin
                    // count up and roll around
                    if (bcd_max) begin
                        bcd<=4'd0;
                    end else begin
                        bcd<=bcd+1'b1;
                    end
                end else begin
                    // count down and roll around
                    if (bcd_min) begin
                        bcd<=4'd9;
                    end else begin
                        bcd<=bcd-1'b1;
                    end
                end
            end
        end
    end
end
assign bcd_min=(bcd==4'h0)?1'b1:1'b0;
assign bcd_max=(bcd==4'h9)?1'b1:1'b0;
assign fs = (up)?(bcd_max):(bcd_min);
assign co = en & fs;

endmodule
