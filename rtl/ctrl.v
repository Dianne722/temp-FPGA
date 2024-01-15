module ctrl (
    input       [15:0]      t_data  ,
    output      [23:0]      dis_data,
    output                  en
);
    
    wire        [23:0]      data_b      ;
    wire        [3:0]       data_b001   ;   //小数点后的第三位
    wire        [3:0]       data_b01    ;   //小数点后的第二位
    wire        [3:0]       data_b1     ;   //小数点后的第一位
    wire        [3:0]       data_1      ;   //个位
    wire        [3:0]       data_10     ;   //十位
    wire        [3:0]       data_fu     ;   //符号位

    assign data_b       = t_data[10:0] * 625; //放大1000倍 数据乘以精度 才是温度
    assign data_b001    = data_b /10 %10    ;
    assign data_b01     = data_b /100 %10   ;      
    assign data_b1      = data_b /1000 %10  ;
    assign data_1       = data_b /10000 %10 ;
    assign data_10      = data_b /100000 %10;
    assign data_fu      = t_data[11] ? 4'hB : 4'hA; //数码管上A的话就显示正号 B的话就显示负号

    assign dis_data = {data_fu,data_10,data_1,data_b1,data_b01,data_b001};
    assign en = (data_1 >= 4'd0 && data_10 >= 4'd3) || (data_1 <= 4'd5 && data_10 == 4'd0);

endmodule