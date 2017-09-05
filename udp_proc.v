`timescale 1ns/1ps
/*
Return the received UPD packets without any further processing.
*/

module udp_proc (
    input               clk,
    input               reset,

    input [7:0]         udp_axis_tdata_in,
    input               udp_axis_tvalid_in,
    input               udp_axis_tlast_in,
    output reg          udp_axis_tready_out,

    output [7:0]        udp_axis_tdata_out,
    output              udp_axis_tvalid_out,
    output              udp_axis_tlast_out,
    input               udp_axis_tready_in
);

wire [9:0]      fifo_din, fifo_dout;
wire            fifo_wr_ena, fifo_rd_ena;
wire            fifo_empty, fifo_full;

reg             fifo_dout_valid;

// FIFO should always keep NOT full to ensure buffer the input udp stream.
// Here suppose the FIFO is not overfull.
assign udp_axis_tready_out = ~fifo_full;
assign fifo_rd_ena = ~fifo_empty;
always @(posedge clk) begin
    if (reset) begin
        fifo_dout_valid <= 1'b0;
    end
    else begin
        fifo_dout_valid <= fifo_rd_ena;
end

assign fifo_wr_ena = udp_axis_tvalid_in;
assign fifo_din = {udp_axis_tlast_in, udp_axis_tvalid_in, udp_axis_tdata_in};
assign udp_axis_tvalid_out = fifo_dout_valid ? fifo_dout[8] : 1'b0;
assign udp_axis_tlast_out = fifo_dout_valid ? fifo_dout[9] : 1'b0;
assign udp_axis_tdata_out = fifo_dout[7:0];

// MSB pop out first
fifo_8inx2048 fifo_i (
  .rst(reset),        // input wire rst
  .wr_clk(clk_32),  // input wire wr_clk
  .rd_clk(clk_8),  // input wire rd_clk
  .din(fifo_din),        // input wire [31 : 0] din
  .wr_en(fifo_wr_ena),    // input wire wr_en
  .rd_en(fifo_rd_ena),    // input wire rd_en
  .dout(fifo_dout),      // output wire [7 : 0] dout
  .full(fifo_full),      // output wire full
  .empty(fifo_empty)    // output wire empty
);

endmodule