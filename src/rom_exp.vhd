-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module performs a table lookup to calculate the
-- function y=0.5^x.
-- The intervals are 0 <= x < 1 and 0.5 <= y < 1.
-- The MSB of exp_o will always be 1.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

entity rom_exp is
   port (
      clk_i   : in  std_logic;
      atten_i : in  std_logic_vector(7 downto 0);
      exp_o   : out std_logic_vector(10 downto 0)
   );
end entity rom_exp;

architecture synthesis of rom_exp is

   type mem_t is array (0 to 255) of std_logic_vector(10 downto 0);
   
   impure function InitRom return mem_t is
      constant scale_x : real := 256.0;
      constant scale_y : real := 2048.0;
      variable x_v     : real;
      variable y_v     : real;
      variable int_v   : integer;
      variable ROM_v   : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 255 loop
         x_v := real(i+1) / scale_x; -- Adding one ensures the exp is never one.
         y_v := exp(x_v*log(0.5));
         int_v := integer(y_v*scale_y+0.5);
         ROM_v(i) := to_stdlogicvector(int_v, 11);
      end loop;

      return ROM_v;
   end function;

   signal mem_r : mem_t := InitRom;

begin

   -- Read from ROM
   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         exp_o <= mem_r(to_integer(atten_i));
      end if;
   end process p_read;

end architecture synthesis;

