--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Package
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : llrf_3hc_pkg.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Synthesis
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : 3rd Hamonic (3HC) Low-Level Radio Frequency (LLRF) package.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package llrf_3hc_pkg is
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type t_slv_arr is array (natural range <>) of std_logic_vector;

  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------
  function f_align_lsb_32(
    data : std_logic_vector
  )
    return std_logic_vector;
end llrf_3hc_pkg;

package body llrf_3hc_pkg is
  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------
  function f_align_lsb_32(
    data : std_logic_vector
  )
    return std_logic_vector is
    variable result : std_logic_vector(
                        31 downto 0
                      ) := (others => '0');
  begin
    assert data'length <= 32
      report "Input vector is wider than 32 bits"
      severity failure;

      result(
        data'length-1
        downto 0
      ) := data;

    return result;
  end function f_align_lsb_32;
end package body llrf_3hc_pkg;