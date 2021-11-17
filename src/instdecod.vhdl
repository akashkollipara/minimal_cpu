entity instdecod is
	port(
		en	: in bit;
		inst	: in bit_vector (31 downto 0);
		f0	: out bit_vector (5 downto 0);
		f1	: out bit_vector (4 downto 0);
		f2	: out bit_vector (4 downto 0);
		f3	: out bit_vector (4 downto 0);
		f4	: out bit_vector (4 downto 0);
		op	: out bit_vector (5 downto 0)
	    );
end entity;

architecture behavioral of instdecod is
begin
	process(en, inst)
	begin
		op <= inst(31 downto 26);
		f4 <= inst(25 downto 21);
		f3 <= inst(20 downto 16);
		f2 <= inst(15 downto 11);
		f1 <= inst(10 downto 6);
		f0 <= inst(5 downto 0);
	end process;
end behavioral;
