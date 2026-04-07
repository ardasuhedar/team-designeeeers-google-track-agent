`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;
    reg data_valid;
    reg [11:0] data;
    wire enc_valid;
    wire [12:0] enc_codeword;
    integer i;

    ecc_sed_encoder dut (
        .clk(clk),
        .rst(rst),
        .data_valid(data_valid),
        .enc_valid(enc_valid),
        .data(data),
        .enc_codeword(enc_codeword)
    );

    function automatic expected_parity;
        input [11:0] data_i;
        begin
            expected_parity = ^data_i;
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_case(input [11:0] data_i, input valid_i);
        reg parity_i;
        begin
            data = data_i;
            data_valid = valid_i;
            #1;
            parity_i = expected_parity(data_i);
            if (enc_valid !== valid_i) fail("enc_valid should follow data_valid");
            if (valid_i) begin
                if (enc_codeword[11:0] !== data_i) fail("enc_codeword payload mismatch");
                if (enc_codeword[12] !== parity_i) fail("enc_codeword parity mismatch");
                if (^enc_codeword !== 1'b0) fail("enc_codeword should have even parity");
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b0;
        data_valid = 1'b0;
        data = 12'h000;

        check_case(12'h000, 1'b1);
        check_case(12'h001, 1'b1);
        check_case(12'h800, 1'b1);
        check_case(12'hAAA, 1'b1);
        check_case(12'h555, 1'b1);
        check_case(12'hFFF, 1'b1);
        check_case(12'h123, 1'b1);
        check_case(12'hABC, 1'b1);
        check_case(12'h000, 1'b0);

        for (i = 0; i < 64; i = i + 1) begin
            check_case((i * 73) & 12'hFFF, 1'b1);
        end

        $display("TESTS PASSED");
        $finish;
    end

endmodule
