library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity er_1octet is
  port ( rst : in std_logic ;
         clk : in std_logic ;
         en : in std_logic ;
         din : in std_logic_vector (7 downto 0) ;
         miso : in std_logic ;
         sclk : out std_logic ;
         mosi : out std_logic ;
         dout : out std_logic_vector (7 downto 0) ;
         busy : out std_logic);
end er_1octet;

architecture behavioral of er_1octet is

  type t_etat is (repos, bit_envoye, bit_receptione);
  signal etat : t_etat;

begin

	process(clk, rst)
		variable cpt: natural;
		variable data : std_logic_vector(7 downto 0);
		
	begin
		if(rst='0')then
			cpt := 7;
			busy <= '0';
			sclk <= '1'; 
			
			etat <= repos;
			
		elsif(rising_edge(clk)) then
		 
	case etat is
	when repos =>
	
		if (en ='1') then
			busy <= '1';
			sclk <= '0';
			data := din;
			cpt := 7;

			mosi <=data(cpt);
			
			etat <= bit_envoye;
			
		else
			null;
		end if;
			
		when bit_envoye =>
		  
		  if cpt > 0 then
				sclk <='1';
				data(cpt) := miso ;
				cpt :=cpt-1;
				etat  <= bit_receptione;
			
			else
				 cpt:=0;
				 data(cpt) := miso;
				 sclk <= '1';
				 dout <=data;
				 busy <='0';
				
				 etat <=repos;
			end if;
		
		when bit_receptione =>
		
			sclk <= '0';
			mosi <= data(cpt);
			
			etat <= bit_envoye;
			
		 end case;
	 end if;
  end process;	
  
end behavioral;