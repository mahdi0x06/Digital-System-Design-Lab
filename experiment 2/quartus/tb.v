`timescale 1ns / 1ps

module tb_WaitingRoom;

    reg Clk;
    reg Reset;
    reg IN_sensor;
    reg OUT_sensor;
    reg Ent;
    reg T;

    wire Open;
    wire Close;
    
    az2 uut (
        .Clk(Clk),
        .Reset(Reset),
        .IN(IN_sensor),
        .OUT(OUT_sensor),
        .Ent(Ent),
        .T(T),
        .Open(Open),
        .Close(Close)
    );

    always #10 Clk = ~Clk;

    initial begin
        // مقداردهی اولیه سیگنال‌ها
        Clk = 0;
        Reset = 0; // فرض بر این است که ریست حساس به سطح پایین است
        IN_sensor = 0;
        OUT_sensor = 0;
        Ent = 0;
        T = 0;

        // سناریو ۱: ریست کردن سیستم
        #20 Reset = 1; // غیرفعال کردن ریست برای شروع کار مدار

        // سناریو ۲: ورود یک نفر در زمان مجاز
        #20 T = 1; Ent = 1; 
        #20 Ent = 0; 
        #20 IN_sensor = 1; // فرد از در عبور می‌کند
        #20 IN_sensor = 0;

        // سناریو ۳: خروج یک نفر و صفر شدن مجدد افراد اتاق
        #40 OUT_sensor = 1;
        #20 OUT_sensor = 0;

        // سناریو ۴: ورود و خروج هم‌زمان
        // ابتدا یک نفر را وارد می‌کنیم تا اتاق خالی نباشد
        #20 T = 1; Ent = 1; #20 Ent = 0; IN_sensor = 1; #20 IN_sensor = 0; 
        // حالا ورود و خروج هم‌زمان
        #40 IN_sensor = 1; OUT_sensor = 1; 
        #20 IN_sensor = 0; OUT_sensor = 0;

        // سناریو ۵: تلاش برای ورود در زمان غیرمجاز
        #40 T = 0; Ent = 1;
        #20 Ent = 0; 
        #20 IN_sensor = 1;
        #20 IN_sensor = 0;

        // سناریو ۶: پر کردن ظرفیت اتاق تا ۱۵ نفر
        T = 1;
        repeat(14) begin
            #10 Ent = 1; #10 Ent = 0;
            #10 IN_sensor = 1; #10 IN_sensor = 0;
        end

        // سناریو ۷: تلاش برای ورود وقتی اتاق پر است
        #40 Ent = 1;
        #20 Ent = 0; 
        #20 IN_sensor = 1;
        #20 IN_sensor = 0;

        #100 $stop;
    end

endmodule