library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the Pulse Width Modulation module.
-- It takes as input a 16-bit signal representing an unsigned value between
-- 0x0.0000 and 0x0.FFFF. This value is interpreted as the required width of
-- each pulse.
--
-- The input clock is 229 MHz.
-- The input waveform is sampled at 112 kHz.

entity pwm is
   port (
      clk_i : in  std_logic;
      wav_i : in  std_logic_vector(15 downto 0);
      pwm_o : out std_logic
   );
end pwm;

architecture synthesis of pwm is

   -- This controls the sample rate.
   -- The signal cnt_r wraps around every 65536/32 = 2048 clock cycles.
   -- This corresponds to an update frequency of 112 kHz.
   constant C_CNT_INC : integer := 32;

   signal cnt_r : std_logic_vector(15 downto 0) := (others => '0');
   signal wav_r : std_logic_vector(15 downto 0) := (others => '0');

   signal pwm_r : std_logic;

begin

   -- This is a free-running counter.
   -- Wraps around once for every sound sample.
   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cnt_r <= cnt_r + C_CNT_INC;

         if (cnt_r+C_CNT_INC) = 0 then
            wav_r <= wav_i;
         end if;
      end if;
   end process p_cnt;

   -- This generates a pulse whose width is proportional to the input value.
   p_pwm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wav_r > cnt_r then
            pwm_r <= '1';
         else
            pwm_r <= '0';
         end if;

         pwm_o <= pwm_r;
      end if;
   end process p_pwm;

end architecture synthesis;

