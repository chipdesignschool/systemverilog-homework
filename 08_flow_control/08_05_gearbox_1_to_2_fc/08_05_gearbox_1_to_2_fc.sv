/*
Задача - реализовать модуль который будет формировать один токен из двух поступивших токенов.
Пример
  "01", "10" => "0110"
Модуль должен использовать сигналы valid-ready при передаче данных.
*/

/*
  Task:
  Implement a module that generates one token from of two tokens.
  Example:
  "01", "10" => "0110"

  The module must use signals valid-ready for transfer tokens.
*/

module gearbox_1_to_2_fc
  # (
      parameter width = 0
    )
  (
        input                  clk,
        input                  rst,
        input                  up_valid,
        output                 up_ready,
        input   [width-1:0]    up_data,
        output                 down_valid,
        output  [2*width-1:0]  down_data,
        input                  down_ready
  );


  /* START SOLUTION*/

   logic [2*width-1 : 0] token;
   logic [width-1 : 0] first_part;
   logic order, ready;

   wire up_handshake = up_ready & up_valid;
   wire down_handshake = down_ready & down_valid;

  always_ff @(posedge clk)
    if (rst) begin
      order <= 1'b0;                             // indicates which part expected
      ready <= 1'b0;                             // indicates ready data or not. It is clone down_valid
    end
    else begin

     if (down_handshake) ready <= 1'b0;

     if (up_handshake == 1'b1)
       if (order) begin
       // if the second part was recived
            token      <= {first_part, up_data};
            order      <= ~order;
            ready      <= 1'b1;
       end
       else begin
       // if the first part was recived
            first_part <= up_data;
            order      <= ~order;
       end
    end

  assign up_ready   = ~ready | down_handshake;
  assign down_valid = ready;
  assign down_data  = token;

  /* END SOLUTION */

endmodule
