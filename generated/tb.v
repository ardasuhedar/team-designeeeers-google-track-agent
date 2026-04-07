`timescale 1ns/1ps

module tb;

    reg  [9:0] bin;
    wire [9:0] gray;
    integer i;

    enc_bin2gray dut (
        .bin(bin),
        .gray(gray)
    );

    function automatic [9:0] expected_gray;
        input [9:0] bin_value;
        begin
            expected_gray = bin_value ^ (bin_value >> 1);
        end
    endfunction

    task automatic check_case;
        input [9:0] bin_value;
        input [8*80-1:0] label;
        reg [9:0] expected_value;
        begin
            bin = bin_value;
            #1;
            expected_value = expected_gray(bin_value);

            if (gray !== expected_value) begin
                $display(
                    "FAIL: %0s bin=%0d expected_gray=%010b got_gray=%010b",
                    label,
                    bin_value,
                    expected_value,
                    gray
                );
                $finish;
            end

            if (gray[9] !== bin_value[9]) begin
                $display(
                    "FAIL: %0s MSB mismatch bin=%010b gray=%010b",
                    label,
                    bin_value,
                    gray
                );
                $finish;
            end
        end
    endtask

    initial begin
        check_case(10'b0000000000, "all_zero");
        check_case(10'b0000000001, "lsb_one");
        check_case(10'b0000000010, "single_bit_1");
        check_case(10'b0000000100, "single_bit_2");
        check_case(10'b0000010000, "single_bit_4");
        check_case(10'b0100000000, "single_bit_8");
        check_case(10'b1000000000, "msb_one");
        check_case(10'b1111111111, "all_one");
        check_case(10'b1010101010, "alternating_a");
        check_case(10'b0101010101, "alternating_5");
        check_case(10'b0011110000, "middle_block");
        check_case(10'b1100001111, "edge_blocks");
        check_case(10'd511, "boundary_511");
        check_case(10'd512, "boundary_512");
        check_case(10'd1023, "max_value");

        for (i = 0; i < 1024; i = i + 1) begin
            check_case(i[9:0], "full_enumeration");
        end

        bin = 10'd0;
        #1;
        if (gray !== expected_gray(10'd0)) begin
            $display("FAIL: initial transition check");
            $finish;
        end

        bin = 10'd341;
        #1;
        if (gray !== expected_gray(10'd341)) begin
            $display("FAIL: combinational update check for 341");
            $finish;
        end

        bin = 10'd682;
        #1;
        if (gray !== expected_gray(10'd682)) begin
            $display("FAIL: combinational update check for 682");
            $finish;
        end

        $display("TESTS PASSED");
        $finish;
    end

endmodule
