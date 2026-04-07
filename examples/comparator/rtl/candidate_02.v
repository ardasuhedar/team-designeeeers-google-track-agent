module comparator4 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire       EQ,
    output wire       GT,
    output wire       LT
);

wire signed [3:0] signed_a;
wire signed [3:0] signed_b;

assign signed_a = A;
assign signed_b = B;
assign EQ = (A == B);
assign GT = (signed_a > signed_b);
assign LT = (signed_a < signed_b);

endmodule
