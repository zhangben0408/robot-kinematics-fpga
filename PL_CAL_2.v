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
// 使用状态机设计
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
    bram_we_1a,
    phase_tdata,
    phase_tvalid,
    sin_tdata,
    sin_tvalid,
    cos_tdata,
    cos_tvalid
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
    
    output [31:0]phase_tdata;
    output phase_tvalid;
    input [31:0]sin_tdata;
    input sin_tvalid;
    input [31:0]cos_tdata;
    input cos_tvalid;
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
	//cordic相关
	wire [31:0]phase_tdata;
	wire phase_tvalid;
	wire [31:0]sin_tdata;
	wire sin_tvalid;
	wire [31:0]cos_tdata;
	wire cos_tvalid;
	//内部线网，作为转移条件
	wire idle_s1_start;
	wire s1_s2_start;
	wire s2_s3_start;
	wire s3_s4_start;
	wire s4_s5_start;
	wire s4_idle_start;
	/*------------------------------------------------*/
	//标志位
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
	//状态寄存器
	reg [2:0]state_current;
	reg [2:0]state_next;
	reg [1:0]subState1;
	reg [1:0]subState3;
	//cordic
	reg [31:0]phase_tdata_reg;
	reg phase_tvalid_reg;
	reg [31:0]sin_data_reg;
	reg [31:0]cos_data_reg;
	//phase_tvalid保持器
	reg [1:0]phase_tvalid_cnt;
	//phase_sincos_flag
	reg phase_sincos_flag_reg;
	//s4_idle_flag
	reg s4_idle_flag_reg;
	/*------------------------------------------------*/
	//主状态
	localparam  IDLE=3'b000,				//起始
				State1=3'b001,				//S1:读BRAM0
				State2=3'b011,				//S2:由phase计算sin，cos
				State3=3'b010,				//S3:写BRAM1
				State4=3'b110,				//S4:更新地址
				State5=3'b111;				//S5:终态
	//State1的子状态
	localparam	subState10=2'b00,
				subState11=2'b01,
				subState12=2'b11,
				subState13=2'b10;
	//State3的子状态
	localparam	subState30=2'b00,
				subState31=2'b01,
				subState32=2'b11,
				subState33=2'b10;
	localparam  BRAM1_ADDRESS_HIGH = 32'd48 - 32'd4;
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
	
	assign phase_tdata=phase_tdata_reg;
	assign phase_tvalid=phase_tvalid_reg;
	/*------------------------------------------------*/
	//检测ps_write_done的上升沿
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
			ps_write_done_reg_1<=ps_write_done_reg_1;
	end	
	/*------------------------------------------------*/
	//逻辑控制,三段式状态机
	//时序逻辑：描述状态转换
	always@(posedge clk)
	begin
		if(!rst_n)
			state_current<=IDLE;
		else
			state_current<=state_next;
	end
	//组合逻辑，描述下一状态
	always@(*)
	begin
		case(state_current)
		IDLE:
			begin
				if(idle_s1_start)
					state_next = State1;
				else
					state_next = state_current;
			end
		State1:
			begin
				if(s1_s2_start)
					state_next = State2;
				else
					state_next = state_current;
			end
		State2:
			begin
				if(s2_s3_start)
					state_next = State3;
				else
					state_next = state_current;
			end
		State3:
			begin
				if(s3_s4_start)
					state_next = State4;
				else
					state_next = state_current;
			end
		State4:
			begin
				if(s4_s5_start)
					state_next = State5;
				else if(s4_idle_start)
					state_next = IDLE;
				else
					state_next = state_current;
			end
		State5:
			state_next = state_current;
		default:
			state_next = IDLE; 	
		endcase
	end
	//转移条件
	assign idle_s1_start = (state_current==IDLE) && (ps_write_done_reg_1==1'b1);
	assign s1_s2_start = (state_current==State1) && (subState1==subState13);
	assign s2_s3_start = (state_current==State2) && (phase_sincos_flag_reg==1'b1);
	assign s3_s4_start = (state_current==State3) && (subState3==subState33);
	assign s4_s5_start = (state_current==State4) && (pl_cal_done_reg==1'b1);
	assign s4_idle_start = (state_current==State4) && (s4_idle_flag_reg==1'b1);
	//输出逻辑，由寄存器锁存后输出数据
	always@(posedge clk)
	begin
		if(!rst_n)
		begin
			bram_addr_0b_reg<=32'd0;
			bram_en_0b_reg<=1'b0;
			bram_we_0b_reg<=4'd0;
			bram_rddata_0b_reg<=32'd0;
				
			bram_addr_1a_reg<=32'd0;
			bram_wrdata_1a_reg<=32'd0;
			bram_en_1a_reg<=1'b0;
			bram_we_1a_reg<=4'd0;

			pl_cal_done_reg<=1'b0;

			phase_sincos_flag_reg<=1'b0;
			subState1<=subState10;
			subState3<=subState30;
			phase_tvalid_cnt<=2'b0;
			s4_idle_flag_reg<=1'b0;
		end 
		else begin
			case(state_current)
			IDLE:
				begin
					subState1<=subState10;
					subState3<=subState30;
					phase_sincos_flag_reg<=1'b0;
					phase_tvalid_cnt<=2'b0;
					s4_idle_flag_reg<=1'b0;
					bram_en_0b_reg<=1'b0;
					bram_we_0b_reg<=4'd0;
				end
			State1:
				begin
					case(subState1)
					subState10:
						begin
							bram_en_0b_reg<=1'b1;
							bram_we_0b_reg<=4'd0;
							subState1 <= subState11;
						end
					subState11:
						begin
							bram_en_0b_reg<=1'b0;
							bram_we_0b_reg<=4'd0;
							subState1 <= subState12;
						end
					subState12:
						begin
							bram_rddata_0b_reg<=bram_rddata_0b;
							subState1 <= subState13;
						end
					default:
						subState1 <= subState10;
					endcase
				end
			State2:
				begin
					phase_tdata_reg <= bram_rddata_0b_reg;
					if(phase_tvalid_cnt < 2'b11)
					begin	
						phase_tvalid_reg <= 1'b1;
						phase_tvalid_cnt <= phase_tvalid_cnt+1'b1;
					end
					else
						phase_tvalid_reg <= 1'b0;

					if((sin_tvalid == 1'b1)&&(cos_tvalid == 1'b1))
					begin
						sin_data_reg <= sin_tdata;
						cos_data_reg <= cos_tdata;
						phase_sincos_flag_reg<=1'b1;
					end
				end
			State3:
				begin
					case(subState3)
					subState30: 
						begin
							bram_en_1a_reg<=1'b1;
							bram_we_1a_reg<=4'hf;
							bram_wrdata_1a_reg<=sin_data_reg;
							subState3<=subState31;
						end
					subState31:
						begin
							bram_en_1a_reg<=1'b0;
							bram_we_1a_reg<=4'h0;
							bram_addr_1a_reg<=bram_addr_1a_reg+32'd4;
							subState3<=subState32;
						end
					subState32:
						begin
							bram_en_1a_reg<=1'b1;
							bram_we_1a_reg<=4'hf;
							bram_wrdata_1a_reg<=cos_data_reg;
							subState3<=subState33;
						end
					subState33:
						begin
							bram_en_1a_reg<=1'b0;
							bram_we_1a_reg<=4'h0;
						end
					default:
						subState3<= subState30;
					endcase
				end
			State4:
				begin
					if(bram_addr_1a_reg==BRAM1_ADDRESS_HIGH)
					begin
						bram_addr_0b_reg<=32'd0;
						bram_addr_1a_reg<=32'd0;
						pl_cal_done_reg<=~pl_cal_done_reg;						
					end
					else if(s4_idle_flag_reg==1'b0)
					begin
						bram_addr_0b_reg<=bram_addr_0b_reg+32'd4;
						bram_addr_1a_reg<=bram_addr_1a_reg+32'd4;
						s4_idle_flag_reg<=1'b1;
 					end
				end
			default:;
			endcase
		end
	end
endmodule
/*旧逻辑
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
					bram_en_1a_reg<=1'b0;
					bram_en_0b_reg<=1'b0;
					bram_we_1a_reg<=4'd0;
					bram_we_0b_reg<=4'd0;
					if(bram_addr_1a_reg==BRAM_ADDRESS_HIGH)
					begin
						bram_addr_0b_reg<=32'd0;
						bram_addr_1a_reg<=32'd0;
						pl_cal_done_reg<=~pl_cal_done_reg;
						state<=State5;
					end
					else begin
						state<=IDLE;
						bram_addr_0b_reg<=bram_addr_0b_reg+32'd4;
						bram_addr_1a_reg<=bram_addr_1a_reg+32'd4;
					end
				end
			State5: begin
					state<=State5;
				end
			default: state<=IDLE;
			endcase
		end
	end*/
