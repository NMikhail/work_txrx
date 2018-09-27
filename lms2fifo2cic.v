module lms2fifo2cic(	
	//Global signal
	input rst_dsp,
	input clk_dsp,
	input clk_data_in,
	//input
	input [23:0] data_in_Ih_Ql,
	//output
	output [49:0] data_out_Ih_Ql,
	//control and error
	output err_fifo2cic_full
);
wire rst_dsp_n = ~rst_dsp;	
//FIFO data
wire [23:0] q;
reg rdreq;
wire rdempty;	
FIFO2CIC i1(
	.data(data_in_Ih_Ql),
	.rdclk(clk_dsp),
	.rdreq(rdreq),
	.wrclk(clk_data_in),
	.wrreq(1'b1),
	.q(q),
	.rdempty(rdempty),
	.wrfull(err_fifo2cic_full),
	.aclr(rst_dsp));
//CIC data 
reg [2:0] ctrl_cic;
wire in_valid			 = ctrl_cic[2];
wire in_startofpacket = ctrl_cic[1];
wire in_endofpacket	 = ctrl_cic[0];
wire in_ready;
reg [11:0] in_data;
CIC_rx i2 (
		.clk               (clk_dsp),     
		.reset_n           (rst_dsp_n),
		.in_error          (2'b00),
		.in_valid          (in_valid),
		.in_ready          (in_ready),
		.in_data           (in_data),
		.in_startofpacket  (in_startofpacket),
		.in_endofpacket    (in_endofpacket),
		.out_data          (out_data),
		.out_error         (out_error),
		.out_valid         (out_valid),
		.out_ready         (out_ready),
		.out_startofpacket (out_startofpacket),
		.out_endofpacket   (out_endofpacket),
		.out_channel       (out_channel)
	);

//System of State Machine	
reg f_data_ready, f_data_done;
//State machine for FIFO control
parameter STATE_FIFO_EMPTY = 0, STATE_FIFO_DATA_WR = 1;
reg state_ctr_fifo;

always @(negedge clk_dsp or posedge rst_dsp)
begin
	if (rst_dsp) begin
		rdreq				<= 0;
		f_data_ready 	<= 0;
		state_ctr_fifo	<= STATE_FIFO_EMPTY;
		end
	else
		case (state_ctr_fifo)
			STATE_FIFO_EMPTY: begin
										f_data_ready	<= 0;
										if (~rdempty) begin
											rdreq 			<= 1;
											state_ctr_fifo <= STATE_FIFO_DATA_WR;
										end
									end
			STATE_FIFO_DATA_WR:
									begin
										rdreq				<= 0;
										f_data_ready 	<= 1;
										if (f_data_done)
											state_ctr_fifo <= STATE_FIFO_EMPTY;
									end									
		endcase
end
//State machine for CIC input control
parameter STATE_CH1_TX = 0, STATE_CH2_TX = 1;
reg state_cic_data_in;

always @(posedge clk_dsp or posedge rst_dsp) begin
	if (rst_dsp) begin
		ctrl_cic 	<= 0;
		f_data_done <= 0;
		state_cic_data_in <= STATE_CH1_TX;
		end
	else
		case (state_cic_data_in)
			STATE_CH1_TX:		begin
										ctrl_cic 	<= 0;										
										if (~f_data_ready)											
											f_data_done <= 0;											
										if (in_ready & f_data_ready) begin
											ctrl_cic <= 3'b110;
											in_data	<= q[23:12];
											state_cic_data_in <= STATE_CH2_TX;
										end
									end
			STATE_CH2_TX:		
									begin
										ctrl_cic <= 3'b101;
										in_data	<= q[11:0];
										f_data_done <= 1;
										state_cic_data_in <= STATE_CH1_TX;
									end
		endcase
end

endmodule 