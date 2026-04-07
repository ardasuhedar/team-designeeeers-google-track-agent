module comparator4 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire       EQ,
    output wire       GT,
    output wire       LT
);

assign EQ = (A == B);
assign GT = (A > B);
assign LT = (A < B);

endmodule
