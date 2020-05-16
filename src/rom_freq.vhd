-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the ROM with the phase increments
-- (frequency) of each note.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

entity rom_freq is
   generic (
      G_CLOCK_HZ : integer -- Frequency of input clock
   );
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(9 downto 0);
      data_o : out std_logic_vector(11 downto 0)
   );
end entity rom_freq;

architecture synthesis of rom_freq is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 1023) of std_logic_vector(11 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable ROM_v          : mem_t := (others => (others => '0'));
      variable note_v         : integer;
      variable freq_v         : real;
      variable phaseinc_v     : integer;

      -- There are 64 fractions per semitone, and 12 semitone per octave.
      constant C_FACTOR       : real := 2.0 ** (1.0/768.0);

      -- Frequency in Hz of the A4 tone.
      constant C_FREQ_A4_HZ   : real := 220.0; -- TBD: Should this be 440 Hz ?

      -- Index 0 corresponds to C#, which is 4 semitones above A4, but 5 octaves lower.
      constant C_FREQ_INDEX_0 : real := C_FREQ_A4_HZ * (C_FACTOR**(4.0*64.0)) / 32.0;

      constant C_SCALE        : real := 2.0**24.0;

   begin
      for i in 0 to 1023 loop
         note_v     := i - (i/64/4)*64;
         freq_v     := C_FREQ_INDEX_0 * (C_FACTOR ** real(note_v));
         phaseinc_v := integer(freq_v/real(G_CLOCK_HZ) * C_SCALE * 32.0);
         ROM_v(i)   := to_stdlogicvector(phaseinc_v, 12);
      end loop;
      return ROM_v;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end architecture synthesis;

