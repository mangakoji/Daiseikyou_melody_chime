-- ===================================================================
-- TITLE : Melody Chime / Sound Generator
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
--     DATE   : 2012/08/17 -> 2012/08/28
--            : 2012/08/28 (FIXED)
--
--     UPDATE : 2015/03/14
-- ===================================================================
-- *******************************************************************
--   Copyright (C) 2012,2015 J-7SYSTEM Works.  All rights Reserved.
--
-- * This module is a free sourcecode and there is NO WARRANTY.
-- * No restriction on use. You can use, modify and redistribute it
--   for personal, non-profit or commercial products UNDER YOUR
--   RESPONSIBILITY.
-- * Redistributions of source code must retain the above copyright
--   notice.
-- *******************************************************************


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity melodychime_sg is
	generic(
		CLOCK_EDGE		: std_logic := '1';		-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';		-- Positive logic reset

		ENVELOPE_TC		: integer := 28000		-- �G���x���[�v���萔(�ꎟ�x��n,t=0.5�b)
	);
	port(
		reset			: in  std_logic;		-- async reset
		clk				: in  std_logic;		-- system clock
		reg_div			: in  std_logic_vector(7 downto 0);		-- �����l�f�[�^(0�`255) 
		reg_note		: in  std_logic;		-- �m�[�g�I��(1:�����J�n / 0:����) 
		reg_write		: in  std_logic;		-- 1=���W�X�^�������� 

		timing_10us		: in  std_logic;		-- clock enable (10us�^�C�~���O,1�p���X��,1�A�N�e�B�u) 
		timing_1ms		: in  std_logic;		-- clock enable (1ms�^�C�~���O,1�p���X��,1�A�N�e�B�u) 

		wave_out		: out std_logic_vector(15 downto 0)		-- �g�`�f�[�^�o��(�����t��16bit) 
	);
end melodychime_sg;

architecture RTL of melodychime_sg is
	signal divref_reg		: std_logic_vector(7 downto 0);
	signal note_reg			: std_logic;

	signal sqdivcount		: std_logic_vector(7 downto 0);
	signal sqwave_reg		: std_logic;

	constant ENVCOUNT_INIT	: std_logic_vector(14 downto 0) := CONV_std_logic_vector(ENVELOPE_TC,15);
	signal env_count_reg	: std_logic_vector(14 downto 0);
	signal env_cnext_sig	: std_logic_vector(14+9 downto 0);

	signal wave_pos_sig		: std_logic_vector(15 downto 0);
	signal wave_neg_sig		: std_logic_vector(15 downto 0);

begin

	-- ���̓��W�X�^ 

	process (clk, reset) begin
		if (reset = RESET_LEVEL) then
			divref_reg <= (others=>'0');
			note_reg   <= '0';

		elsif (clk'event and clk = CLOCK_EDGE) then
			if (reg_write = '1') then
				divref_reg <= reg_div;
			end if;

			if (reg_write = '1' and reg_note = '1') then
				note_reg <= '1';
			elsif (timing_1ms = '1') then
				note_reg <= '0';
			end if;

		end if;
	end process;


	-- ��`�g���� 

	process (clk, reset) begin
		if (reset = RESET_LEVEL) then
			sqdivcount <= (others=>'0');
			sqwave_reg <= '0';

		elsif (clk'event and clk = CLOCK_EDGE) then
			if (timing_10us = '1') then
				if (sqdivcount = 0) then
					sqdivcount <= divref_reg;
					sqwave_reg <= not sqwave_reg;
				else
					sqdivcount <= sqdivcount - 1;
				end if;
			end if;

		end if;
	end process;


	-- �G���x���[�v���� 

	process (clk, reset)
		variable env_cnext_val	: std_logic_vector(env_count_reg'length + 9-1 downto 0);
	begin
		if (reset = RESET_LEVEL) then
			env_count_reg <= (others=>'0');

		elsif (clk'event and clk = CLOCK_EDGE) then
			if (timing_1ms = '1') then
				if (note_reg = '1') then
					env_count_reg <= ENVCOUNT_INIT;
				elsif (env_count_reg /= 0) then
					env_cnext_val := (env_count_reg & "000000000") - ("000000000" & env_count_reg);
					env_count_reg <= env_cnext_val(14+9 downto 0+9);	-- vonext = ((vo<<9) - vo)>>9
				end if;
			end if;

		end if;
	end process;


	-- �g�`�U���ϒ��Əo�� 

	wave_pos_sig <= '0' & env_count_reg;
	wave_neg_sig <= 0 - wave_pos_sig;

	wave_out <= wave_pos_sig when(sqwave_reg = '1') else wave_neg_sig;



end RTL;
