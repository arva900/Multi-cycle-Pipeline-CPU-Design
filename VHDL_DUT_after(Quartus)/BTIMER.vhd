LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY BTIMER IS
	generic ( MEMwitdh : integer :=12);
	PORT( Mclk,Mclk2,Mclk4,Mclk8,Mrst 		: IN 	STD_LOGIC;
			MemRead 			: IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   	: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PWMout 				: OUT 	STD_LOGIC;	
			set_BTIFG 			: OUT 	STD_LOGIC
			);
END BTIMER;

ARCHITECTURE BTIMER_arch OF BTIMER IS
signal READbus,WRITEbus,BTCNT,BTCNT_in,BTCL0,BTCL1: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
signal BTCTL : STD_LOGIC_VECTOR( 7 DOWNTO 0 );


signal enwr,BTOUTMD,BTOUTEN,BTHOLD :STD_LOGIC;
signal BTSSEL :STD_LOGIC_VECTOR( 1 DOWNTO 0 );
signal BTIPx :STD_LOGIC_VECTOR( 2 DOWNTO 0 );

signal clk,Q0,Q3,Q7,Q11,Q15,Q19,Q23,Q25,done :STD_LOGIC;


BEGIN 
READbus <= DATA_bus( 31 DOWNTO 0 );
DATA_bus <= WRITEbus WHEN enwr='1' else ( others =>'Z');


BTOUTMD<=BTCTL(7);
BTOUTEN<=BTCTL(6);
BTHOLD <=BTCTL(5);
BTSSEL <=BTCTL(4 downto 3);
BTIPx  <=BTCTL(2 downto 0);

with BTSSEL SELECT
	clk <=	Mclk2 WHEN "01",
		Mclk4 WHEN "10",
		Mclk8 WHEN "11", 
		Mclk WHEN others; --"00"
		
with BTIPx SELECT
	set_BTIFG <=	Q0 	WHEN "000",
			Q3	WHEN "001",
			Q7 	WHEN "010",
			Q11	WHEN "011",
			Q15 	WHEN "100",
			Q19	WHEN "101",
			Q23	WHEN "110", 
			Q25 	WHEN others; --"111"
		

BTlatches: PROCESS(Mclk,MemRead,addressBUS,READbus,MemWrite,Mrst)
begin
IF Mrst = '1' THEN
	BTCTL <= X"20"; --BTHOLD='1'
	BTCNT_in <= (OTHERS => '0');
	BTCL0 <= (OTHERS => '0');
	BTCL1 <= (OTHERS => '0');
	enwr<='0';

elsif (mclk'event and mclk ='0') then
	case addressBUS(11 downto 0) IS
		-- BTCTL
		WHEN X"81C" 	=>	
			IF (MemWrite ='1') THEN	
				BTCTL <= READbus(7 DOWNTO 0);
				enwr <= '0' ;

			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= X"000000"&BTCTL;
			END IF;
		-- BTCNT
	 	WHEN X"820" 	=>	
			IF (MemWrite ='1') THEN	
				BTCNT_in <= READbus;
			enwr <= '0' ;

			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCNT;
			END IF;
		-- BTCCR0
		WHEN X"824" 	=>
			IF (MemWrite ='1') THEN	
				BTCL0 <= READbus;
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCL0;
			END IF;
		-- BTCCR1		
 	 	WHEN X"828" 	=>	
			IF (MemWrite ='1') THEN	
				BTCL1 <= READbus;
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCL1;
			END IF;
 	 	WHEN OTHERS	=>	enwr <= '0' ;
  	END CASE;
END IF;

end process;



----BTCNT REGISTER COUNTING PROCESS
process (clk,Mrst,BTCNT_in)
begin
	if (Mrst ='1') then
		BTCNT <= (others =>'0');
   elsif (rising_edge(clk)) then	
		if (done='1') then
		BTCNT <= (others =>'0');
		elsIF (BTHOLD ='0' and done ='0') then
				BTCNT <= BTCNT + 1;

		ELSIF(addressBUS = X"820" and MemWrite ='1')then
				BTCNT <= BTCNT_in;	
		end if;
	end if;
end process;


/*
process (Q0,Q3,Q7,Q11,Q15,Q19,Q23,Q25)
begin
assert FALSE
report "[Q0="& to_string(Q0)&"]";
report "[Q3="& to_string(Q3)&"]";
report "[Q7="& to_string(Q7)&"]";
report "[Q11="& to_string(Q11)&"]";
report "[Q15="& to_string(Q15)&"]";
report "[Q19="& to_string(Q19)&"]";
report "[Q23="& to_string(Q23)&"]";
report "[Q25="& to_string(Q25)&"]";
end process;*/

----BTCNT REGISTER OVERFLOW PROCESS
WITH BTCNT SELECT 
	Q0  <='1' WHEN X"00000002",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q3  <='1' WHEN X"00000008",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q7  <='1' WHEN X"00000080",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q11  <='1' WHEN X"00000800",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q15  <='1' WHEN X"00008000",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q19  <='1' WHEN X"00080000",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q23  <='1' WHEN X"00800000",
		'0' WHEN OTHERS;
WITH BTCNT SELECT 
	Q25  <='1' WHEN X"02000000",
		'0' WHEN OTHERS;





PROCESS(BTCNT,BTOUTMD,BTOUTEN)
--(BTCL0 -BTCL1)/ BTCL0 = dutycycle
BEGIN
	IF (BTOUTMD='0' AND BTOUTEN = '1') THEN
		IF (BTCNT >= BTCL1 AND BTCNT < BTCL0) THEN
			PWMout <= '1';
done <='0';
		ELSIF (BTCNT >= BTCL0) THEN
			PWMout <= '0';
done <='1';
		Else
			PWMout <= '0';
done <='0';
		END IF;
	ELSIF (BTOUTMD='1' AND BTOUTEN = '1' ) THEN
		IF (BTCNT >= BTCL1 AND BTCNT < BTCL0) THEN
			PWMout <= '0';
done <='0';
		ELSIF (BTCNT >= BTCL0) THEN
			PWMout <= '1';
done <='1';
		ELSE
			PWMout <= '1';
done <='0';
		END IF;
	ELSE 
	PWMout <= '0';
	done <='0';
	END IF;
END PROCESS;

END BTIMER_arch;
