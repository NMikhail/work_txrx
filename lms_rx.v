module lms_rx(
	//export rx
	input							mclk_rx,
	input 			[11:0] 	dio_rx,
	input 						iqsel_rx,
	output						fclk_rx,
	output						rxen_rx,
	output						txnrx_rx,
	//signal_out
	output			[23:0] 	data_Ih_Ql,
	output	reg				clk_data_in
);

assign rxen_rx 	= 1;
assign txnrx_rx 	= 0;
assign fclk_rx 	= 0;

parameter CH_A = 0, CH_B = 1;

reg [11:0] DAI, DAQ;
assign data_Ih_Ql = {DAI, DAQ};

//I компонента
always @(posedge mclk_rx)
begin
	if (iqsel_rx == CH_A)
		DAI <= dio_rx;
end
//Q компонента
always @(negedge mclk_rx)
begin
	if (iqsel_rx == CH_A)
		DAQ <= dio_rx;
end
//Тактовый сигнал данных
always @(posedge mclk_rx)
begin
	clk_data_in <= ~iqsel_rx;
end

endmodule
					