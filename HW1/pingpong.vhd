LIBRARY IEEE;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pingpong is

    port(
   	    clk  	    : in std_logic;
        rst 	    : in std_logic;
	    BUTTON_R    : in std_logic;
	    BUTTON_L	: in std_logic;
	    SW          : in std_logic_vector ((8-1) downto 0);
--**
        led         : out std_logic_vector ((8-1) downto 0)
--**        
--        SEG1 : out std_logic_vector(6 downto 0);
--        SEG2 : out std_logic_vector(6 downto 0)
        );
		  
		  
end pingpong;

architecture Behavioral of pingpong is
type gamestate is(right_to_left, left_to_right, right_win, left_win, wait_BUTTON_L, wait_BUTTON_R,wait_R_start,wait_L_start);
signal ball_state : gamestate;
signal LED_s, LED_s2 : std_logic_vector(7 downto 0):="00000001";
signal light_cnt : std_logic_vector(7 downto 0);
signal count_R,  count_L: std_logic_vector(3 downto 0);
signal clk_new   : std_logic_vector(25 downto 0);
signal clk_pingpong, clk_PWM :  std_logic;

signal flag  :  std_logic;

signal Q     : std_logic_vector(5 downto 0):="000001";
signal random_num : std_logic_vector(1 downto 0);
signal random_cnt : std_logic_vector(1 downto 0);
signal temp  : std_logic;
signal random_clk : std_logic;
signal BUTTON_L_F, BUTTON_R_F : std_logic;
--signal SEG1 :  std_logic_vector(6 downto 0);
--signal SEG2 :  std_logic_vector(6 downto 0);

begin

LFSR_random:process(rst, clk)
begin
    if rst = '1'then 
--        temp <= '0';
        Q    <= "000001";
    elsif(clk'event and clk = '1')then
--        temp <= Q(5) xor '1';
        Q(5) <= Q(4);
        Q(4) <= Q(3);
        Q(3) <= Q(2) xor Q(5);
        Q(2) <= Q(1);
        Q(1) <= Q(0) xor Q(5);
        Q(0) <=  Q(5) xor '1';
        
    end if;
end process;
random_num <= Q(1 downto 0);

random_CLK_cnt:process(rst, clk_pingpong, random_num)
begin
    if rst = '1'then 
        random_clk <= '0';
        random_cnt <= "00";
    elsif(clk_pingpong'event and clk_pingpong = '1')then
        if (random_cnt + 1) < random_num  then
            random_cnt <= random_cnt + '1';
        else
            random_clk <= not random_clk;
            random_cnt <= "00";
        end if;      
    end if;
end process;

clock:process(clk, rst)   --¤é »
begin
	if(rst = '1') then
		 clk_new <= (others => '0');
	elsif(clk'event and clk = '1') then
		 clk_new <= clk_new + 1;	
	end if;
end process;



wait_button:process(clk, rst, ball_state, BUTTON_R, BUTTON_L)   --¤é »
begin
	if(rst = '1') then
		 BUTTON_L_F <= '0';
		 BUTTON_R_F <= '0';
	elsif(clk'event and clk = '1') then
		case ball_state is
		    when wait_BUTTON_R =>
		        if(BUTTON_R = '1')then
		            BUTTON_R_F <= '1';
		        end if;
		    when wait_BUTTON_L =>
		        if(BUTTON_L = '1')then
                    BUTTON_L_F <= '1';
                end if; 
            when right_to_left =>
                BUTTON_R_F <= '0';
            when left_to_right =>
                BUTTON_L_F <= '0';
            when others =>
                null;
         end case;	
	end if;
end process;

STATE: PROCESS(clk, rst, ball_state, LED_s, flag, BUTTON_R_F, BUTTON_L_F, BUTTON_R, BUTTON_L)
begin  
	if(rst = '1')then
		ball_state <=  right_to_left;
		count_R <= "0000";
		count_L <= "0000";
		
	elsif(clk'event and clk = '1')then	
		case ball_state is
			when right_to_left =>--å¾?å·¦ç™¼
				
				if LED_s(7)= '1' then
					ball_state <= wait_BUTTON_L;			
				else
					if BUTTON_L = '1' then --å·¦é¶æ
						ball_state <= right_win; --³éè´
					end if;
				end if;
				
			when left_to_right =>--å¾?³ç™¼
				
				if LED_s(0) = '1' then
					ball_state <= wait_BUTTON_R;
				else
					if BUTTON_R = '1' then --å·¦éè´
						ball_state <= left_win;
					end if;
				end if;
				
			when right_win => --³éè´
				ball_state <= wait_R_start;
				count_R <= count_R +'1';
				
			when wait_R_start =>
			    if BUTTON_R = '1' then --å·¦éè´
			        ball_state <= right_to_left;
                end if;


			when left_win => --å·¦éè´
                count_L <= count_L +'1';
                ball_state <= wait_L_start;

			when wait_L_start =>
			    if BUTTON_L = '1' then --å·¦éè´
                    ball_state <= left_to_right;
                end if;
                
			when wait_BUTTON_L =>
			    if flag = '1'then
                    if BUTTON_L_F = '1' then --å·¦é¥ä
                        ball_state <= left_to_right;
                    else
                        ball_state <= right_win;
                    end if;
				end if;
			when wait_BUTTON_R =>
                if flag = '1'then
                    if BUTTON_R_F = '1' then --³é¥ä
                        ball_state <= right_to_left;
                    else
                        ball_state <= left_win;
                    end if;
                end if;
		end case;
		
	end if;
end process;

LED_counter: PROCESS(random_clk, rst, ball_state)
begin  
	if(rst = '1')then
		LED_s <= "00000001";	
		flag <= '0';
	elsif(random_clk'event and random_clk = '1')then	
		case ball_state is
			when right_to_left =>--å¾?å·¦ç™¼
				if LED_s = "00001111"then
				    LED_s <= "00000001";
				else
				    LED_s <= LED_s(6 downto 0) & '0';
				end if;
                flag <= '0';
                				
			when left_to_right =>--å¾?³ç™¼
			    if LED_s = "11110000"then
                    LED_s <= "10000000";
                else    
                    LED_s <= '0' & LED_s(7 downto 1);
                end if;                          
                flag <= '0';
                
			when wait_BUTTON_L => --³éè´

				flag <= '1';
				
            when wait_BUTTON_R => --³éè´

                flag <= '1';

			when wait_R_start =>
			
			    LED_s <= "00001111";
				
--			when left_win => --å·¦éè´
--				LED_s <= "11110000";

			when wait_L_start =>
			    LED_s <= "11110000";
			    
			when others =>
				null;
		end case;
		
	end if;
end process;

light_PWM:process(clk_PWM, LED_s, SW)   --¤é »
begin
	if(rst = '1') then
		LED_s2 <= (others => '0');
		light_cnt <= (others => '0');
	elsif(clk_PWM'event and clk_PWM = '1') then
		if(light_cnt< SW)then
		    LED_s2 <=  LED_s;
		elsif(light_cnt >= SW and light_cnt < "11111111")then
		    LED_s2 <= (others => '0');
		end if;
		if(light_cnt = "11111111")then
		    light_cnt <= (others => '0');
		else 
		    light_cnt <= light_cnt + '1';
		end if;	
	end if;
end process;
led <= LED_s2;
clk_pingpong <= clk_new(21);
clk_PWM <= clk_new(8);
end Behavioral;