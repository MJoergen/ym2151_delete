-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the interface to the CPU.
--
-- This module stores all the configruation information, and circulates through
-- the 32 devices and outputs the configuration for the current device.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity config is
   port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      cen_i          : in  std_logic;
      -- CPU interface
      cfg_valid_i    : in  std_logic;
      cfg_ready_o    : out std_logic;
      cfg_addr_i     : in  std_logic_vector(7 downto 0);
      cfg_data_i     : in  std_logic_vector(7 downto 0);
      -- Configuration output
      device_idx_o   : out std_logic_vector(4 downto 0);
      key_code_o     : out std_logic_vector(6 downto 0);
      key_fraction_o : out std_logic_vector(5 downto 0)
   );
end entity config;

architecture synthesis of config is

   ----------------------------------------------------
   -- Channel configuration
   ----------------------------------------------------

   type byte_vector_t is array (0 to 7) of std_logic_vector(7 downto 0);
   signal key_code_r          : byte_vector_t := (others => (others => '0'));
   signal key_fraction_r      : byte_vector_t := (others => (others => '0'));


   ----------------------------------------------------
   -- Device index
   ----------------------------------------------------

   signal device_idx_r        : std_logic_vector(4 downto 0) := (others => '0');

   signal key_code_read_r     : std_logic_vector(7 downto 0);
   signal key_fraction_read_r : std_logic_vector(7 downto 0);

begin

   ----------------------------------------------------
   -- Channel configuration
   ----------------------------------------------------

   p_key_code : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cfg_valid_i = '1' and cfg_addr_i(7 downto 3) = "00101" then
            key_code_r(to_integer(cfg_addr_i(2 downto 0))) <= "0" & cfg_data_i(6 downto 0);
         end if;
      end if;
   end process p_key_code;

   p_key_fraction : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cfg_valid_i = '1' and cfg_addr_i(7 downto 3) = "00110" then
            key_fraction_r(to_integer(cfg_addr_i(2 downto 0))) <= "00" & cfg_data_i(7 downto 2);
         end if;
      end if;
   end process p_key_fraction;


   ----------------------------------------------------
   -- Device index
   ----------------------------------------------------

   p_device_idx : process (clk_i)
   begin
      if rising_edge(clk_i) and cen_i = '1' then
         device_idx_r <= device_idx_r + 1;
      end if;
   end process p_device_idx;


   ----------------------------------------------------
   -- Read configuration from memories
   ----------------------------------------------------

   p_register : process (clk_i)
   begin
      if rising_edge(clk_i) then
         device_idx_o        <= device_idx_r;
         key_code_read_r     <= key_code_r(to_integer(device_idx_r(2 downto 0)));
         key_fraction_read_r <= key_fraction_r(to_integer(device_idx_r(2 downto 0)));
      end if;
   end process p_register;


   ----------------------------------------------------
   -- Drive output signals
   ----------------------------------------------------

   key_code_o     <= key_code_read_r(6 downto 0);
   key_fraction_o <= key_fraction_read_r(5 downto 0);

   cfg_ready_o    <= '1';

end architecture synthesis;

