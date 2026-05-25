module clock_div_2pow20 (
    input  wire clk,
    input  wire enable,
    output wire clk_div
);

reg [19:0] counter = 20'h0;

always @(posedge clk ) 
        counter <= counter + 1'b1;
assign clk_div = enable ? counter[19] : clk;
endmodule
