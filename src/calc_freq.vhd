-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the phase increment,
-- based on the note being played.
--
-- Latency is 2 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity calc_freq is
   generic (
      G_CLOCK_HZ : integer                -- Input clock frequency
   );
   port (
      clk_i       : in  std_logic;
      note_i      : in  std_logic_vector(6 downto 0);
      fraction_i  : in  std_logic_vector(5 downto 0);
      phase_inc_o : out std_logic_vector(19 downto 0)
   );
end entity calc_freq; 

architecture synthesis of calc_freq is

   -- Stage 0
   signal octave_s       : std_logic_vector(2 downto 0);
   signal key_s          : std_logic_vector(3 downto 0);
   signal addr_s         : std_logic_vector(9 downto 0);

   -- Stage 1
   signal octave_I_r     : std_logic_vector(2 downto 0);
   signal freq_I_s       : std_logic_vector(11 downto 0);

   -- Stage 2
   signal phase_inc_II_r : std_logic_vector(23 downto 0);

begin

   ----------------------------------------------------
   -- Stage 0
   ----------------------------------------------------

   octave_s <= note_i(6 downto 4);
   key_s    <= note_i(3 downto 0);
   addr_s   <= key_s & fraction_i;


   ----------------------------------------------------
   -- Stage 1
   ----------------------------------------------------

   p_stage1 : process (clk_i) begin
      if rising_edge(clk_i) then
         octave_I_r <= octave_s;
      end if;
   end process p_stage1;

   i_rom_freq : entity work.rom_freq
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i  => clk_i,
         addr_i => addr_s,
         data_o => freq_I_s
      ); -- i_rom_freq


   ----------------------------------------------------
   -- Stage 2
   ----------------------------------------------------

   -- Shift frequency based on octave number
   p_phase_inc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         phase_inc_II_r <= (others => '0');
         phase_inc_II_r(11+to_integer(octave_I_r)
                    downto to_integer(octave_I_r)) <= freq_I_s;
      end if;
   end process p_phase_inc;

   phase_inc_o <= phase_inc_II_r(23 downto 4);

end architecture synthesis;

