/**************************************************************
 * Module: send_top
 * Porject: Packet filter in 10Gb/s network
 * Description:
 * 1)
 **************************************************************/

`timescale 1ns / 1ps

module send_top (
    input          clk,
    input          reset,

    //Local IP and MAC
    input [31:0]        local_IP_in,
    input [47:0]        local_MAC_in,

    // IP and MAC address is from the incoming ARP packet
    input [31:0]        remote_ip_addr_in,
    input [47:0]        remote_mac_addr_in,
    input               arp_reply_in,
    output              arp_reply_ack_out,

    input [1:0]    op,
    //inputs from application software to UDP/TCP stack
    input             data_from_app_valid,
    input [31:0]      data_from_app,
    input [3:0]       data_from_app_keep,
    input             data_from_app_last,
    input [31:0]      dest_ip_addr,
    input [15:0]      dest_port,
    input [15:0]      data_from_app_length,

    input [7:0]       tcp_ctrl_type,

    /* output interface
    */
    output [31:0]     tdata,
    output [3:0]      tkeep,
    output            tvalid,
    output            tlast,
    input             tready
);

   // The IP and MAC addresses for the FPGA:
wire [31:0]      SPA;
assign SPA = local_IP_in;
wire [47:0]      SHA;
assign SHA = local_MAC_in;

// Outputs of udp_send_module
wire [15:0]         udp_data_length;
wire [31:0]         udp_data_to_ip;
wire                udp_data_valid;
wire [3:0]          udp_data_keep;
wire                udp_data_last;
wire [31:0]         ip_addr;

// TCP send
wire [31:0]         tcp_data;
wire                tcp_data_valid;
wire [15:0]         tcp_data_length;
wire [3:0]          tcp_data_keep;
wire                tcp_data_last;

// Outputs of IP_send_module
wire [31:0]         ip_send_ip_addr, send_ip_data, send_ip_data_r1;
wire                udp_ready, send_ip_valid;
wire [3:0]          send_ip_keep;
wire                send_ip_last;

// Outputs from arp_send_module
wire                arp_send_valid, reply_ready, request_ready;
wire [31:0]         arp_send_data;
wire [3:0]          arp_send_keep;
wire                arp_send_last;
wire [47:0]         arp_mac_addr;

// Outputs from send_buffer_module
wire                ip_send_ready, arp_send_ready, req_en, r_mac_cache_en;//, cpu_ip_ready, cpu_arp_ready;
wire [31:0]         arp_send_ip_addr, r_mac_cache_ip_addr, cpu_ip_data, cpu_arp_data;
wire                request_ack_out;
// AXI-4 signals
wire [31:0]       tdata_r1, tdata_r2;

udp_send udp_send_module
  (
   .clk(clk),
   .reset(reset),
   //from software app

   .data_in(data_from_app),
   .data_valid_in(data_from_app_valid),
   .data_keep_in  (data_from_app_keep),
   .data_last_in  (data_from_app_last),
   .op(op),
   .ip_addr_in(dest_ip_addr),
   .dest_port(dest_port),

   .length_in(data_from_app_length),
   .data_out(udp_data_to_ip),
   .data_valid_out(udp_data_valid),
   .data_keep_out (udp_data_keep),
   .data_last_out (udp_data_last),

   .length_out(udp_data_length)
   );
tcp_send tcp_send_module
  (
   .clk(clk),
   .reset(reset),
   //from software app
   .data_in_valid(data_from_app_valid),
   .data_in(data_from_app),
   .ctrl_type(tcp_ctrl_type),
   .op(op),
   .ip_addr_in(dest_ip_addr),
   .dest_port(dest_port),
   .length_in(data_from_app_length),
   // TCP data output
   //.ip_addr_out(ip_addr),
   .tcp_data_valid_out(tcp_data_valid),
   .tcp_data_out(tcp_data),
   .tcp_length_out(tcp_data_length)
   );


ip_send ip_send_module
  (
   .clk(clk),
   .reset(reset),

   .ip_addr(dest_ip_addr),
   // from UDP send
   .udp_data_in(udp_data_to_ip),
   .udp_valid_in(udp_data_valid),
   .udp_keep_in       (udp_data_keep),
   .udp_last_in       (udp_data_last),
   .udp_data_length_in(udp_data_length),

   // from TCP send
   .tcp_data_in(tcp_data),
   .tcp_valid_in(tcp_data_valid),
   .tcp_keep_in       (tcp_data_keep),
   .tcp_last_in       (tcp_data_last),
   .tcp_data_length_in(tcp_data_length),
   // send buffer
   .ready(ip_send_ready),
   // output ports
   .oip_addr(ip_send_ip_addr),
   .udp_ready(udp_ready),
   .tdata(send_ip_data),
   .tkeep(send_ip_keep),
   .tlast(send_ip_last),
   .tvalid(send_ip_valid)
   );

arp_send arp_send_module
  (
    .clk(clk),
    .reset(reset),
    .remote_ip_addr_in    (remote_ip_addr_in),
    .remote_mac_addr_in   (remote_mac_addr_in),
    .ip_addr_request_in (arp_send_ip_addr),    // requested ip from send_buffer_module
    .SPA_in(SPA),
    .SHA_in(SHA),
    .request_en_in(req_en),                        // req_en from send_buffer_module
    .request_ack_out     (request_ack_out),
    .reply_en_in(arp_reply_in),
    .reply_ack_out       (arp_reply_ack_out),
    .send_buffer_ready_in(arp_send_ready),


    .arp_tdata_out (arp_send_data),
    .arp_tvalid_out (arp_send_valid),
    .arp_tkeep_out (arp_send_keep),
    .arp_tlast_out (arp_send_last),
    //.reply_ready(reply_ready),
    .request_ready_out(request_ready)
   //.arp_mac_addr(arp_mac_addr)
   );

send_buffer send_buffer_module
  (
   .clk(clk),
   .reset(reset),
   //ip send
   .ip_send_addr(ip_send_ip_addr),
   .ip_send_data(send_ip_data),
   .ip_send_valid(send_ip_valid),
   .ip_send_keep (send_ip_keep),
   .ip_send_last (send_ip_last),
   .ip_send_ready(ip_send_ready),
   //arp_send
   //**send reply ports
   .arp_send_mac_addr('h0),
   .arp_send_data(arp_send_data),
   .arp_send_valid(arp_send_valid),
   .arp_send_keep (arp_send_keep),
   .arp_send_last (arp_send_last),
   .arp_send_ready(arp_send_ready),
   //**send request ports
   .req_ready(request_ready),          //
   .arp_send_ip_addr(arp_send_ip_addr), // requsted ip
   .req_en(req_en),
   //mac_cache
   .r_mac_addr(48'hF),
   .r_mac_cache_en(r_mac_cache_en),
   .r_mac_cache_ip_addr(r_mac_cache_ip_addr),

   .tdata(tdata),
   .tvalid(tvalid),
   .tkeep(tkeep),
   .tlast(tlast),
   .tready(1'b1)

   );
endmodule
