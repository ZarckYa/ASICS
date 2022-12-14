//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: 4-digit BCD up counter, with clr input, stopping at full-scale
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

module bcd_counter_4d
(
	
    input wire          clk,                // clock input
    input wire          reset,              // reset input (synchronous)
    input wire          en,                 // counting enabled
    input wire          clr,                // clears counter (to 0)
    input wire [15:0]  	bcdin,
    output wire         fs,                 // flag indicating that full-scale (9,999) was reached
    output wire [15:0]  bcd               // bcd out (4 digits)
);

// wires and regs
wire [3:0]      co;
wire [3:0]      fs_digits;
wire            en_cnt;


// create full-scale signal
//assign fs = !fs_digits;
assign fs = fs_digits[0] & fs_digits[1] & fs_digits[2] & fs_digits[3];

// create a count enable signal
assign en_cnt = en&(~fs);

// instantiate the digits
bcd_counter_digit bcd0
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(en_cnt),
    .load(clr),
    .value(bcdin[3:0]),
    .bcd(bcd[3:0]),
    .co(co[0]),
    .fs(fs_digits[0])
);

bcd_counter_digit bcd1
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[0]),
    .load(clr),
    .value(bcdin[7:4]),
    .bcd(bcd[7:4]),
    .co(co[1]),
    .fs(fs_digits[1])
);

bcd_counter_digit bcd2
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[1]),
    .load(clr),
    .value(bcdin[11:8]),
    .bcd(bcd[11:8]),
    .co(co[2]),
    .fs(fs_digits[2])
);

bcd_counter_digit bcd3
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[2]),
    .load(clr),
    .value(bcdin[15:12]),
    .bcd(bcd[15:12]),
    .co(co[3]),
    .fs(fs_digits[3])
);

endmodule
