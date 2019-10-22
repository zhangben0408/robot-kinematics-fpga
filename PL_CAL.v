`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: zhangben
// 
// Create Date: 2019/09/18 21:38:25
// Design Name: 
// Module Name: PL_Calculate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 上升沿操作，反复触发，触发一次计算一次
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PL_Calculate(
    clk,
    rst_n,
    ps_write_done,
    pl_cal_done,
    bram_addr_0b,
    bram_clk_0b,
    bram_wrdata_0b,
    bram_rddata_0b,
    bram_en_0b,
    bram_rst_0b,
    bram_we_0b,
    bram_addr_1a,
    bram_clk_1a,
    bram_wrdata_1a,
    bram_rddata_1a,
    bram_en_1a,
    bram_rst_1a,
    bram_we_1a
    );

    //接口方向及位宽声明
    input clk;
    input rst_n;
    
    input ps_write_done;
    output pl_cal_done;
    
    output [31:0]bram_addr_0b;
    output bram_clk_0b;
    output [31:0]bram_wrdata_0b;
    input [31:0]bram_rddata_0b;
    output bram_en_0b;
    output bram_rst_0b;
    output [3:0]bram_we_0b;
    
    output [31:0]bram_addr_1a;
    output bram_clk_1a;
    output [31:0]bram_wrdata_1a;
    input [31:0]bram_rddata_1a;
    output bram_en_1a;
    output bram_rst_1a;
    output [3:0]bram_we_1a;
    /*--------------------------------------------------*/
	wire clk;
	wire rst_n;
	
	wire ps_write_done;
	wire pl_cal_done;
	
	wire [31:0]bram_addr_0b;
	wire bram_clk_0b;
	wire [31:0]bram_wrdata_0b;
	wire [31:0]bram_rddata_0b;
	wire bram_en_0b;
	wire bram_rst_0b;
	wire [3:0]bram_we_0b;
	
	wire [31:0]bram_addr_1a;
	wire bram_clk_1a;
	wire [31:0]bram_wrdata_1a;
	wire [31:0]bram_rddata_1a;
	wire bram_en_1a;
	wire bram_rst_1a;
	wire [3:0]bram_we_1a;
	/*------------------------------------------------*/
	reg ps_write_done_reg_0;
	reg ps_write_done_reg_1;
	reg pl_cal_done_reg;
	//BRAM_0b只读
	reg [31:0]bram_addr_0b_reg;
	reg [31:0]bram_rddata_0b_reg;
	reg bram_en_0b_reg;
	reg [3:0]bram_we_0b_reg;
	//BRAM_1a只写
	reg [31:0]bram_addr_1a_reg;
	reg [31:0]bram_wrdata_1a_reg;
	reg bram_en_1a_reg;
	reg [3:0]bram_we_1a_reg;
	
	reg [2:0]state;
	/*------------------------------------------------*/
	localparam  IDLE=3'b000,
				State1=3'b001,
				State2=3'b011,
				State3=3'b010,
				State4=3'b110,
				State5=3'b111;
	localparam  BRAM_ADDRESS_HIGH = 32'd4096 - 32'd4;
	/*------------------------------------------------*/
	assign pl_cal_done=pl_cal_done_reg;
	
	assign bram_clk_0b=clk;
	assign bram_rst_0b=~rst_n;
	assign bram_addr_0b=bram_addr_0b_reg;
	assign bram_en_0b=bram_en_0b_reg;
	assign bram_we_0b=bram_we_0b_reg;
	
	assign bram_clk_1a=clk;
	assign bram_rst_1a=~rst_n;
	assign bram_addr_1a=bram_addr_1a_reg;
	assign bram_wrdata_1a=bram_wrdata_1a_reg;
	assign bram_en_1a=bram_en_1a_reg;
	assign bram_we_1a=bram_we_1a_reg;
	/*------------------------------------------------*/
	always @ (posedge clk)
	begin
		if(!rst_n)
			ps_write_done_reg_0<=1'b0;
		else
			ps_write_done_reg_0<=ps_write_done;
	end
	
	always @ (posedge clk)
	begin
		if(!rst_n)
			ps_write_done_reg_1<=1'b0;
		else if ({ps_write_done_reg_0,ps_write_done}==2'b01)
			ps_write_done_reg_1<=1'b1;
		else
			ps_write_done_reg_1<=1'b0;
	end
	
	
	always @ (posedge clk)
	begin
		if(!rst_n)
		begin
			state<=IDLE;
				
			bram_addr_0b_reg<=32'd0;
			bram_en_0b_reg<=1'b0;
			bram_we_0b_reg<=4'd0;
			bram_rddata_0b_reg<=32'd0;
				
			bram_addr_1a_reg<=32'd0;
			bram_wrdata_1a_reg<=32'd0;
			bram_en_1a_reg<=1'b0;
			bram_we_1a_reg<=4'd0;
			
			pl_cal_done_reg<=1'b0;
			
		end	
		else begin
			case(state)
			IDLE: begin
					if(ps_write_done_reg_1)
					begin
						bram_en_0b_reg<=1'b1;
						bram_we_0b_reg<=4'd0;
						state<=State1;
					end
					else begin
						state<=IDLE;
						bram_en_0b_reg<=1'b0;
						bram_we_0b_reg<=4'd0;
						bram_addr_0b_reg<=bram_addr_0b_reg;
						
						bram_en_1a_reg<=1'b0;
						bram_we_1a_reg<=4'd0;
						bram_addr_1a_reg<=bram_addr_1a_reg;
					end
				end
			State1: begin
					bram_en_0b_reg<=1'b0;
                    state<=State2;
                end
            State2:begin
					bram_rddata_0b_reg<=bram_rddata_0b;
					state<=State3;
				end
			State3: begin
					bram_en_1a_reg<=1'b1;
					bram_we_1a_reg<=4'hf;
					bram_wrdata_1a_reg<=bram_rddata_0b_reg+31'd2;
					state<=State4;
				end
			State4: begin
					state<=IDLE;
					bram_en_1a_reg<=1'b0;
					bram_en_0b_reg<=1'b0;
					bram_we_1a_reg<=4'd0;
					bram_we_0b_reg<=4'd0;
					if(bram_addr_1a_reg==BRAM_ADDRESS_HIGH)
					begin
						bram_addr_0b_reg<=32'd0;
						bram_addr_1a_reg<=32'd0;
						pl_cal_done_reg<=~pl_cal_done_reg;
						
					end
					else begin
						bram_addr_0b_reg<=bram_addr_0b_reg+32'd4;
						bram_addr_1a_reg<=bram_addr_1a_reg+32'd4;
					end
				end
			default: state<=IDLE;
			endcase
		end
	end
endmodule
