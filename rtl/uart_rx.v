module uart_rx (
    input               clk     ,
    input               rst_n   ,
    input               din     ,   //pc端发送给FPGA的数据
    output  reg [7:0]   dout    ,   //发送给tx 让他串行的传出去
    output  reg         dout_vld    //当这一次8bit接收完成 再传给tx
);


    parameter BAUD = 434 ;  //使用波特率115200 发送1bit所需要的时钟周期

    reg     [8:0]       cnt_bsp     ;
    wire                add_cnt_bsp ;
    wire                end_cnt_bsp ;

    reg     [3:0]       cnt_bit     ;   //计数当前到了哪一bit了 计数9bit 起始位加上数据
    wire                add_cnt_bit ;
    wire                end_cnt_bit ;

    reg                 din_r0      ;   //同步到时钟上升沿
    reg                 din_r1      ;   //打拍 延时一个时钟周期
    wire                nedge       ;   //下降沿
    reg                 flag        ;   //计数器计数的标志 下降沿到来之后开始计数 传输数据完成了就停止计数
    reg     [8:0]       data        ;   //寄存数据

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt_bsp <= 9'b0;
        end
        else if(add_cnt_bit)begin
            if(end_cnt_bsp)begin
                cnt_bsp <= 9'b0;
            end
            else begin
                cnt_bsp <= cnt_bsp + 1'b1;
            end
        end
        else begin
            cnt_bsp <= cnt_bsp;
        end
    end

    assign add_cnt_bsp = flag;
    assign end_cnt_bsp = add_cnt_bsp && cnt_bsp == BAUD - 1;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt_bit <= 4'b0;
        end
        else if(add_cnt_bit)begin
            if(end_cnt_bit)begin
                cnt_bit <= 4'b0;
            end
            else begin
                cnt_bit <= cnt_bit + 1'b1;
            end
        end
        else begin
            cnt_bit <= cnt_bit;
        end
    end

    assign add_cnt_bit = end_cnt_bsp;
    assign end_cnt_bit = add_cnt_bit && cnt_bit == 8; //起始位加上8bit数据位

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            din_r0 <= 1'b1;
            din_r1 <= 1'b1;
        end
        else begin
            din_r0 <= din;
            din_r1 <= din_r0;
        end
    end

    assign nedge = ~din_r0 & din_r1; 

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            flag <= 1'b0;
        end
        else if(nedge)begin
            flag <= 1'b1;
        end
        else if(end_cnt_bit)begin
            flag <= 1'b0;
        end
        else begin
            flag <= flag;
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data <= 9'b0;
        end
        else if(cnt_bsp == (BAUD >> 1) && flag)begin
            data[cnt_bit] <= din;   //串并转换  LSB
        end
        else begin
            data <= data;
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dout <= 8'b0;
            dout_vld <= 1'b0;   
        end
        else if(end_cnt_bit)begin
            dout <= data[8:1];  //第0位是起始位 舍弃掉
            dout_vld <= 1'b1;
        end
        else begin
            dout <= dout;
            dout_vld <= 1'b0;
        end
    end

    



endmodule