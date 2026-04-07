`timescale 1ns/1ps

module tb;
    reg  [3:0] A;
    reg  [3:0] B;
    wire       EQ;
    wire       GT;
    wire       LT;

    integer test_count;
    integer fail_count;

    comparator4 dut (
        .A(A),
        .B(B),
        .EQ(EQ),
        .GT(GT),
        .LT(LT)
    );

    task check_case;
        input [3:0] a_in;
        input [3:0] b_in;
        input       exp_eq;
        input       exp_gt;
        input       exp_lt;
        input [255:0] label;
        begin
            A = a_in;
            B = b_in;
            #1;
            test_count = test_count + 1;

            if ((EQ !== exp_eq) || (GT !== exp_gt) || (LT !== exp_lt)) begin
                fail_count = fail_count + 1;
                $display(
                    "FAIL %0d %0s A=%0d B=%0d expected EQ=%0d GT=%0d LT=%0d got EQ=%0d GT=%0d LT=%0d",
                    test_count, label, A, B, exp_eq, exp_gt, exp_lt, EQ, GT, LT
                );
            end else begin
                $display(
                    "PASS %0d %0s A=%0d B=%0d observed EQ=%0d GT=%0d LT=%0d",
                    test_count, label, A, B, EQ, GT, LT
                );
            end

            if ((EQ + GT + LT) !== 1) begin
                fail_count = fail_count + 1;
                $display(
                    "FAIL %0d one_hot_violation A=%0d B=%0d EQ=%0d GT=%0d LT=%0d",
                    test_count, A, B, EQ, GT, LT
                );
            end
        end
    endtask

    initial begin
        test_count = 0;
        fail_count = 0;
        A = 4'd0;
        B = 4'd0;

        $display("Starting comparator4 verification");

        check_case(4'd0,  4'd0,  1'b1, 1'b0, 1'b0, "equal_zero");
        check_case(4'd1,  4'd1,  1'b1, 1'b0, 1'b0, "equal_small");
        check_case(4'd15, 4'd15, 1'b1, 1'b0, 1'b0, "equal_max");

        check_case(4'd1,  4'd0,  1'b0, 1'b1, 1'b0, "gt_basic");
        check_case(4'd0,  4'd1,  1'b0, 1'b0, 1'b1, "lt_basic");
        check_case(4'd8,  4'd7,  1'b0, 1'b1, 1'b0, "unsigned_boundary_gt");
        check_case(4'd7,  4'd8,  1'b0, 1'b0, 1'b1, "unsigned_boundary_lt");
        check_case(4'd15, 4'd0,  1'b0, 1'b1, 1'b0, "max_vs_zero");
        check_case(4'd0,  4'd15, 1'b0, 1'b0, 1'b1, "zero_vs_max");
        check_case(4'd9,  4'd6,  1'b0, 1'b1, 1'b0, "high_bit_gt");
        check_case(4'd6,  4'd9,  1'b0, 1'b0, 1'b1, "high_bit_lt");
        check_case(4'd14, 4'd8,  1'b0, 1'b1, 1'b0, "both_high_gt");
        check_case(4'd8,  4'd14, 1'b0, 1'b0, 1'b1, "both_high_lt");
        check_case(4'd3,  4'd12, 1'b0, 1'b0, 1'b1, "cross_nibble_lt");
        check_case(4'd12, 4'd3,  1'b0, 1'b1, 1'b0, "cross_nibble_gt");

        if (fail_count == 0) begin
            $display("RESULT: PASS all %0d directed tests passed", test_count);
            $finish(0);
        end else begin
            $display("RESULT: FAIL %0d issues found across %0d tests", fail_count, test_count);
            $finish(1);
        end
    end
endmodule
