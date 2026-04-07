`timescale 1ns/1ps

module tb;

    reg [95:0] in;
    reg [2:0] shift;
    reg [11:0] fill;
    wire out_valid;
    wire [95:0] out;
    integer i;

    shift_left dut (
        .out_valid(out_valid),
        .in(in),
        .shift(shift),
        .fill(fill),
        .out(out)
    );

    function automatic [95:0] expected_out;
        input [95:0] in_i;
        input [2:0] shift_i;
        input [11:0] fill_i;
        integer idx;
        reg [95:0] temp;
        begin
            temp = 96'b0;
            for (idx = 0; idx < 8; idx = idx + 1) begin
                if (idx < shift_i) begin
                    temp[idx*12 +: 12] = fill_i;
                end else begin
                    temp[idx*12 +: 12] = in_i[(idx-shift_i)*12 +: 12];
                end
            end
            expected_out = temp;
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_case(input [95:0] in_i, input [2:0] shift_i, input [11:0] fill_i);
        reg [95:0] exp_i;
        begin
            in = in_i;
            shift = shift_i;
            fill = fill_i;
            #1;
            if (out_valid !== (shift_i <= 3'd5)) fail("out_valid mismatch");
            if (shift_i <= 3'd5) begin
                exp_i = expected_out(in_i, shift_i, fill_i);
                if (out !== exp_i) begin
                    $display("FAIL: shift_left mismatch shift=%0d expected=%024h got=%024h", shift_i, exp_i, out);
                    $finish;
                end
            end
        end
    endtask

    initial begin
        check_case(96'h001_002_003_004_005_006_007_008, 3'd0, 12'hABC);
        check_case(96'h001_002_003_004_005_006_007_008, 3'd1, 12'hABC);
        check_case(96'h001_002_003_004_005_006_007_008, 3'd2, 12'h111);
        check_case(96'h001_002_003_004_005_006_007_008, 3'd5, 12'hFED);
        check_case(96'hAAA_BBB_CCC_DDD_EEE_FFF_123_456, 3'd6, 12'h999);
        check_case(96'hAAA_BBB_CCC_DDD_EEE_FFF_123_456, 3'd7, 12'h999);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
