module reset_gen
(
    input  clk_i,
    output rst_o
);

reg [3:0] count_q = 4'b0;
reg       rst_q   = 1'b1;

always @(posedge clk_i) 
if (count_q != 4'hF)
    count_q <= count_q + 4'd1;
else
    rst_q <= 1'b0;

assign rst_o = rst_q;

endmodule