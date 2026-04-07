`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;
    reg in_valid;
    reg [3:0] in;
    wire [14:0] out;
    integer i;

    enc_bin2onehot dut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in(in),
        .out(out)
    );

    function automatic [14:0] expected_out;
        input [3:0] in_i;
        input valid_i;
        begin
            if (!valid_i) begin
                expected_out = 15'b0;
            end else begin
                expected_out = 15'b1 << in_i;
            end
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_case(input [3:0] in_i, input valid_i);
        reg [14:0] exp_i;
        begin
            in = in_i;
            in_valid = valid_i;
            #1;
            exp_i = expected_out(in_i, valid_i);
            if (out !== exp_i) begin
                $display("FAIL: in=%0d valid=%0d expected=%015b got=%015b", in_i, valid_i, exp_i, out);
                $finish;
            end
            if (!valid_i && out !== 15'b0) fail("out should be zero when in_valid is low");
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b0;
        in_valid = 1'b0;
        in = 4'd0;

        for (i = 0; i < 15; i = i + 1) begin
            check_case(i[3:0], 1'b1);
        end
        check_case(4'd0, 1'b0);
        check_case(4'd7, 1'b0);
        check_case(4'd14, 1'b0);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
