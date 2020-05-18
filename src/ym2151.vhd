-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- The input clock frequency should nominally be 3.579545 MHz.
-- The output is an unsigned value representing a fractional
-- output between logical 0 and logical 1.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151 is
   generic (
      G_CLOCK_HZ : integer := 3579545     -- Input clock frequency
   );
   port (
      clk_i       : in  std_logic;
      rst_i       : in  std_logic;
      -- Configuration interface
      cfg_valid_i : in  std_logic;
      cfg_ready_o : out std_logic;
      cfg_addr_i  : in  std_logic_vector(7 downto 0);
      cfg_data_i  : in  std_logic_vector(7 downto 0);
      -- Waveform output
      wav_o       : out std_logic_vector(15 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   signal cen_r          : std_logic := '0';

   signal device_idx_s   : std_logic_vector(4 downto 0);
   signal key_code_s     : std_logic_vector(6 downto 0);
   signal key_fraction_s : std_logic_vector(5 downto 0);

   signal phase_inc_s    : std_logic_vector(19 downto 0);
   signal cnt_r          : std_logic_vector(4 downto 0);
   signal phase_r        : std_logic_vector(19 downto 0);

   signal sin_s          : std_logic_vector(15 downto 0) := (others => '0');

   constant C_OFFSET     : std_logic_vector(15 downto 0) := X"8000";

begin

   ----------------------------------------------------
   -- Generate clock enable
   ----------------------------------------------------

   p_cen : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cen_r <= not cen_r;
      end if;
   end process p_cen;


   ----------------------------------------------------
   -- Process configuration writes
   ----------------------------------------------------

   i_config : entity work.config
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i,
         cen_i          => cen_r,
         cfg_valid_i    => cfg_valid_i,
         cfg_ready_o    => cfg_ready_o,
         cfg_addr_i     => cfg_addr_i,
         cfg_data_i     => cfg_data_i,
         device_idx_o   => device_idx_s,
         key_code_o     => key_code_s,
         key_fraction_o => key_fraction_s
      ); -- i_config


   ----------------------------------------------------
   -- Calculate frequency from note.
   ----------------------------------------------------

   i_calc_freq : entity work.calc_freq
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i       => clk_i,
         note_i      => key_code_s,
         fraction_i  => key_fraction_s,
         phase_inc_o => phase_inc_s
      ); -- i_calc_freq


   ----------------------------------------------------
   -- Generate linearly increasing phase.
   ----------------------------------------------------

   p_phase : process (clk_i)
   begin
      if rising_edge(clk_i) and cen_r = '1' then
         cnt_r <= cnt_r + 1;
         if cnt_r = 0 then
            phase_r <= phase_r + phase_inc_s;
         end if;

         if rst_i = '1' then
            cnt_r   <= (others => '0');
            phase_r <= (others => '0');
         end if;
      end if;
   end process p_phase;


   ----------------------------------------------------
   -- Calculate sin of the phase
   ----------------------------------------------------

   i_calc_sine : entity work.calc_sine
      port map (
         clk_i   => clk_i,
         phase_i => phase_r(19 downto 10),
         sin_o   => sin_s(15 downto 2)
      );

   -- Convert from signed to unsigned.
   wav_o <= sin_s xor C_OFFSET;

end architecture synthesis;

