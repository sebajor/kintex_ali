`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2020 11:17:00 PM
// Design Name: 
// Module Name: bram_intf
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

//DISCARD!!!!


module bram_intf #(
    parameter word_addr = 4096,
    parameter word_size = 64
)

    (
    input clk,
    input arst,
    input [word_size-1:0] tge_tdata,
    input tge_tvalid,
    output tge_tready,
    
    output [31:0] addr,
    output [word_size-1:0] dout,
    output en,
    output rst, 
    output [(word_size/8)-1:0] we
    );
    /*
    rst is active high!
    the axi bram controller is byte-addressing.... to use it with custom 
    logic we have to set the address interface in 32 bits in the mem generator
    So in the custom logic we have to create the a byte addressing in the 
    custom logic.
    */
    reg rst_sys;
    reg rst_fifo = 2'h0;
    always@(posedge clk or negedge arst)begin
            if(arst)
                {rst_sys, rst_fifo} <= {rst_fifo, 1'b1};
            else
                {rst_sys, rst_fifo} <= 3'h0;
    end
    
    
    
    reg [$clog2(word_addr)-1:0] addr_counter;
    reg [(word_size/8)-1:0] we_r;
    reg [word_size-1:0] dout_r;
    
    
    always@(posedge clk or rst)begin
        if(rst_sys) begin
            addr_counter <= 0;
            we_r <= {(word_size/8){1'b0}};
            dout_r <= tge_tdata;
        end
        else begin
            dout_r <= tge_tdata;
            if(tge_tvalid) begin
                we_r <= {(word_size/8){1'b1}};
                addr_counter <= addr_counter +1;
                
            end
        end
    end
    
    
    assign en = 1'b1;
    assign rst = 1'b0;
    assign tge_tready = 1'b1;
    assign addr = {addr_counter, 2'b0};
    assign dout = dout_r;
    assign we = we_r;
    
endmodule
    
    