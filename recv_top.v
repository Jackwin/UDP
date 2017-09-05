`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/16/2016 08:32:54 PM
// Design Name:
// Module Name: recv_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`define BROAD_ADDR 48'hffffffffffff
module recv_top
(
    input           clk,
    input           reset,
    input [47:0]    mac_addr,
    input [31:0]    local_ip_addr,
   // AXI stream interface
    input [7:0]     axis_tdata_in,
    input           axis_tvalid_in,
    input           axis_tlast_in,
    output          axis_tready_o,


    //ARP
    input           reply_ready_in,
    output [31:0]   remote_ip_addr_out,
    output [47:0]   remote_mac_addr_out,
    // Send out the remote ARP request
    input           arp_reply_ack_in,
    output          arp_reply_out

);

wire [7:0]         ip_data;
wire                ip_data_valid;
wire                ip_data_last;

wire [7:0]          arp_data;
wire                arp_data_valid;
wire                arp_data_last;
wire [7:0]          udp_data;
wire                udp_valid;
wire                udp_axis_tready_out;

wire [7:0]          udpdata_tdata_out;
wire                udpdata_tvalid_out;
wire                udpdata_tlast_out;

wire [7:0]          tcp_data;
wire                tcp_valid;

recv_buffer recv_buffer_module
(
    .clk (clk),
    .reset (reset),
    .mac_addr (`BROAD_ADDR),
    .axis_tdata_in (axis_tdata_in),
    .axis_tvalid_in (axis_tvalid_in),
    .axis_tlast_in (axis_tlast_in),
    .axis_tready_o (axis_tready_o),

    .axis_tready_in     (1'b1),
    .arp_axis_tdata_out (arp_data),
    .arp_axis_tvalid_out (arp_data_valid),
    .arp_axis_tlast_out (arp_data_last),

    .ip_axis_tdata_out (ip_data),
    .ip_axis_tvalid_out (ip_data_valid),
    .ip_axis_tlast_out (ip_data_last)
);

udp_rcv udp_rcv_module
(
    .clk(clk),
    .reset              (reset),
    .udp_axis_tdata_in (ip_data),
    .udp_axis_tvalid_in (ip_data_valid),
    .udp_axis_tlast_in  (ip_data_last),
    .udp_axis_tready_out(udp_axis_tready_out),

    .udpdata_tready_in  (1'b1),
    .udpdata_tdata_out  (udpdata_tdata_out),
    .udpdata_tvalid_out (udpdata_tvalid_out),
    .udpdata_tlast_out  (udpdata_tlast_out)
);

arp_recv arp_recv_module
(
    .clk (clk),
    .reset              (reset),
    .arp_tdata_in       (arp_data),
    .arp_tvalid_in      (arp_data_valid),
    .arp_tlast_in       (arp_data_last),
    .local_ip_addr      (local_ip_addr),

    .reply_ready_in     (reply_ready_in),
    .remote_ip_addr_out (remote_ip_addr_out),
    .remote_mac_addr_out(remote_mac_addr_out),
    .arp_reply_ack      (arp_reply_ack_in),
    .arp_reply_out      (arp_reply_out)

);

endmodule
