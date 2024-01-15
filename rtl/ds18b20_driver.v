module ds18b20_driver(
    input                   clk     ,
    input                   rst_n   ,
    inout                   dq      ,          //单总线 可以输入输出的总线
    output  reg  [15:0]     t_data              //读取出来的温度2个字节
);

    parameter   INIT =  3'd1    ,   //初始化
                SKIP =  3'd2    ,   //rom指令 跳过rom
                CT   =  3'd3    ,   //功能指令 转换温度
                WAIT =  3'd4    ,   //等待750ms
                RDCM =  3'd5    ,   //功能指令 读取温度
                RD   =  3'd6    ;   //读出温度

    parameter   TIME_1MS    = 50_000    ,      
                TIME_750MS  = 37_500_000,      
                TIME_65US   = 3250      ;         

    wire                init2skip       ;
    wire                skip2ct         ;
    wire                skip2rdcm       ;
    wire                ct2wait         ;
    wire                wait2init       ;
    wire                rdcm2rd         ;
    wire                rd2init         ;

    reg     [2:0]       state_c         ;   //现态
    reg     [2:0]       state_n         ;   //次态

    reg     [15:0]      cnt_1ms         ;   //复位脉冲和存在脉冲用的计数器
    wire                add_cnt_1ms     ;
    wire                end_cnt_1ms     ;

    reg     [25:0]      cnt_750ms       ;   //等待750ms
    wire                add_cnt_750ms   ;
    wire                end_cnt_750ms   ;

    reg     [11:0]      cnt_65us        ;   //记读0读1写0写1 至少 60us的计数器 
    wire                add_cnt_65us    ;
    wire                end_cnt_65us    ;

    reg     [2:0]       cnt_8bit        ;   //记ROM命令 和 功能命令 8bit
    wire                add_cnt_8bit    ;
    wire                end_cnt_8bit    ;

    reg     [3:0]       cnt_16bit       ;   //记读取温度16bit 
    wire                add_cnt_16bit   ;
    wire                end_cnt_16bit   ;

    reg                 present_flag    ;   //检测有没有存在脉冲
    reg                 skip_flag       ;   //控制功能命令 转换温度和读取温度一个一次

    wire                dq_in           ;   //dq的输入 从机给到主机 读
    reg                 dq_out          ;   //dq的输出 主机给到从机 写
    reg                 dq_en           ;   //控制dq什么时候输出 什么时候输入

    assign  dq_in = dq;                     //输入时 存放到 dq_in
    assign  dq = dq_en ? dq_out : 1'bz  ;   //高阻态的意思 释放总线
    
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_1ms <= 0;
        end 
        else if(add_cnt_1ms)begin 
            if(end_cnt_1ms)begin 
                cnt_1ms <= 0;
            end
            else begin 
                cnt_1ms <= cnt_1ms + 1;
            end 
        end
        else begin 
            cnt_1ms <= cnt_1ms;
        end 
    end 

    assign add_cnt_1ms = state_c == INIT;
    assign end_cnt_1ms = add_cnt_1ms && cnt_1ms == TIME_1MS - 1 ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_750ms <= 0;
        end 
        else if(add_cnt_750ms)begin 
            if(end_cnt_750ms)begin 
                cnt_750ms <= 0;
            end
            else begin 
                cnt_750ms <= cnt_750ms + 1;
            end 
        end
        else begin 
            cnt_750ms <= cnt_750ms;
        end 
    end 

    assign add_cnt_750ms = state_c == WAIT;
    assign end_cnt_750ms = add_cnt_750ms && cnt_750ms ==  TIME_750MS - 1;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_65us <= 0;
        end 
        else if(add_cnt_65us)begin 
            if(end_cnt_65us)begin 
                cnt_65us <= 0;
            end
            else begin 
                cnt_65us <= cnt_65us + 1;
            end 
        end
        else begin 
            cnt_65us <= cnt_65us;
        end 
    end 

    assign add_cnt_65us = state_c == SKIP || state_c == CT || state_c == RDCM || state_c == RD;
    assign end_cnt_65us = add_cnt_65us && cnt_65us ==  TIME_65US - 1;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_8bit <= 0;
        end 
        else if(add_cnt_8bit)begin 
            if(end_cnt_8bit)begin 
                cnt_8bit <= 0;
            end
            else begin 
                cnt_8bit <= cnt_8bit + 1;
            end 
        end
        else begin 
            cnt_8bit <= cnt_8bit;
        end 
    end 
    assign add_cnt_8bit = (end_cnt_65us) && (state_c == SKIP || state_c == CT || state_c == RDCM) ;
    assign end_cnt_8bit = add_cnt_8bit && cnt_8bit == 7 ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_16bit <= 0;
        end 
        else if(add_cnt_16bit)begin 
            if(end_cnt_16bit)begin 
                cnt_16bit <= 0;
            end
            else begin 
                cnt_16bit <= cnt_16bit + 1;
            end 
        end
        else begin 
            cnt_16bit <= cnt_16bit;
        end 
    end 
    assign add_cnt_16bit = (end_cnt_65us) && (state_c == RD);
    assign end_cnt_16bit = add_cnt_16bit && cnt_16bit == 15 ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            present_flag <= 0;
        end 
        else if(cnt_1ms == 30000 && dq_in == 1'b0)begin     //在600us的时候采样 检测有没有存在脉冲
            present_flag <= 1'b1;
        end 
        else if(state_c == SKIP)begin
            present_flag <= 1'b0;
        end
        else begin 
            present_flag <= present_flag;
        end 
    end

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            skip_flag <= 0;     //skip_flag为1跳转到CT  为0跳转到RDCM
        end 
        else if(init2skip)begin 
            skip_flag <= ~skip_flag;
        end 
        else begin 
            skip_flag <= skip_flag;
        end 
    end

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            state_c <= INIT;
        end 
        else begin 
            state_c <= state_n;
        end 
    end

    always @(*)begin
        case(state_c)
            INIT    :   if(init2skip)
                            state_n = SKIP;
                        else 
                            state_n = state_c;
            SKIP    :   if(skip2ct)
                            state_n = CT;
                        else if(skip2rdcm)
                            state_n = RDCM;
                        else 
                            state_n = state_c;
            CT      :   if(ct2wait)
                            state_n = WAIT;
                        else 
                            state_n = state_c;
            WAIT    :   if(wait2init)
                            state_n = INIT;
                        else 
                            state_n = state_c;
            RDCM    :   if(rdcm2rd)
                            state_n = RD;
                        else 
                            state_n = state_c;
            RD      :   if(rd2init)
                            state_n = INIT;
                        else 
                            state_n = state_c;       
            default :   state_n = state_c;
        endcase
    end

    assign init2skip = state_c == INIT  && end_cnt_1ms && present_flag  ;
    assign skip2ct   = state_c == SKIP  && end_cnt_8bit && skip_flag    ;
    assign skip2rdcm = state_c == SKIP  && end_cnt_8bit && ~skip_flag   ;
    assign ct2wait   = state_c == CT    && end_cnt_8bit                 ;
    assign wait2init = state_c == WAIT  && end_cnt_750ms                ;
    assign rdcm2rd   = state_c == RDCM  && end_cnt_8bit                 ;
    assign rd2init   = state_c == RD    && end_cnt_16bit                ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dq_en   <=  1'b0;
            dq_out  <=  1'b0;
            t_data  <=  16'b0;
        end
        else begin
            case(state_c)
                INIT    :   begin       //初始化 拉低总线500us
                            if(cnt_1ms <= 25000)begin
                                dq_en  <= 1'b1;
                                dq_out <= 1'b0;
                            end
                            else begin      //释放总线 检测存在脉冲
                                dq_en  <= 1'b0;
                                dq_out <= 1'b0;
                            end
                end
                SKIP    :   begin       //发送rom指令 跳过rom cc 1100 1100
                            if(cnt_8bit == 3'd2 || cnt_8bit == 3'd3 || cnt_8bit == 3'd6 || cnt_8bit == 3'd7)begin   //写1
                                if(cnt_65us <= 100)begin  //拉低2us
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else if(cnt_65us > 100 && cnt_65us < 3100)begin //拉高60us
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b1;
                                end
                                else begin                  //释放总线 写0写1之间需要释放总线大于1us
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                            else begin  //写0
                                if(cnt_65us < 3100)begin    //拉低62us
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else begin                  //释放总线3us
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                end
                CT      :   begin   //发送功能命令 温度转换 44 0100_0100
                            if(cnt_8bit == 3'd2 || cnt_8bit == 3'd6)begin  //写1
                                if(cnt_65us <= 100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else if(cnt_65us > 100 && cnt_65us < 3100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b1;
                                end
                                else begin
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                            else begin      //写0
                                if(cnt_65us < 3100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else begin
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                end
                WAIT    :   begin   dq_en <= 1'b0; dq_out <= 1'b0; end 
                RDCM    :   begin   //发送读取温度指令  BE  1011_1110
                            if(cnt_8bit == 3'd0 || cnt_8bit == 3'd6)begin  //写0
                                if(cnt_65us < 3100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else begin
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                            else begin      //写1
                                if(cnt_65us <= 100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b0;
                                end
                                else if(cnt_65us > 100 && cnt_65us < 3100)begin
                                    dq_en  <= 1'b1;
                                    dq_out <= 1'b1;
                                end
                                else begin
                                    dq_en  <= 1'b0;
                                    dq_out <= 1'b0;
                                end
                            end
                end
                RD      :   begin   //读取16bit温度数据
                            if(cnt_65us < 100)begin  //拉低2us
                                dq_en  <= 1'b1;
                                dq_out <= 1'b0;
                            end
                            else begin  //释放总线 由从机控制总线传数据到主机
                                dq_en  <= 1'b0;
                                dq_out <= 1'b0;
                                if(cnt_65us == 400 )begin           //20us的时候进行采样
                                    t_data[cnt_16bit] <= dq_in;     //LSB 串并转换
                                end
                            end
                end
                default :   begin 
                                dq_en   <= 1'b0;
                                dq_out  <= 1'b0;
                                t_data  <= 1'b0;
                end
            endcase
        end
    end     

endmodule