pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
	cls()
	mode="start"
	level=""
	debug=""
	levelnum=1
	levels={}
	levels[1]="x6b"
	levels[2]="x7b"
	--levels[1]="hxixsxpxb"
	levels[1]="i99999"
end 

function _update60()
 if mode=="game" then
  update_game()
 elseif mode=="start" then
 	update_start()
 elseif mode=="gameover" then
		update_gameover()
	elseif mode=="levelover" then
  update_levelover()
 end
end

function update_start()
	if btnp("5") then
	 startgame()
	end
end

function startgame()
	ball_r=2
	ball_dr=1
	
	pad_x=52
	pad_y=120
	pad_dx=0
	pad_w=24
	pad_h=3
	pad_c=7

	--brick_y=20
	brick_w=9
	brick_h=4

	levelnum=1
	level=levels[levelnum]
	buildbricks(level)
	
	mode="game"
	lives=3
	points=0
	sticky = true

	chain=1 -- combo chain multiplier

	serveball()
end

function nextlevel()
	mode="game"
	pad_x=52
	pad_y=120
	pad_dx=0

	levelnum+=1
	if levelnum > #levels then
		-- game complete
		mode="start"
		return
	end
	level=levels[levelnum]
	buildbricks(level)

	sticky = true
	chain=1 -- combo chain multiplier

	serveball()
end


function buildbricks(lvl)
	local i,j,chr,last
	brick_x={}
	brick_y={}
	brick_v={}
	brick_t={}
	
	j=0
	-- b = normal brick
	-- x = empty space
	-- i = indestructable brick
	-- h = hardened brick
	-- s = exploding brick
	-- p = powerup brick

	for i=1,#lvl do
		j+=1
		chr=sub(lvl,i,i)
		if chr=="b" 
		or chr=="i"
		or chr=="h"
		or chr=="s"
		or chr=="p" then
			last=chr
			addbrick(j,chr)
		elseif chr=="x" then
			last="x"
		elseif chr=="/" then
			j=flr((j-1)/11+1)*11
		elseif chr>="0" and chr<="9" then
			for o=1,chr+0 do
				if last=="b" 
				or last=="i"
				or last=="h"
				or last=="s"
				or last=="p" then
					addbrick(j,last)
				elseif last=="x" then
					--nothing
				end
				j+=1
			end
			j-=1
		end
	end
end

function addbrick(_i,_t)
	add(brick_x,4+((_i-1)%11)*(brick_w+2))
	add(brick_y,20+flr((_i-1)/11)*(brick_h+2))
	add(brick_v,true)
	add(brick_t,_t)
end

function levelfinished()
	if #brick_v == 0 then return true end

	for i=1,#brick_v do
		if brick_v[i] == true and brick_v[i] != "i" then
			return false
		end
	end
	return true
end


function serveball()
	ball_x=pad_x+flr(pad_w/2)
	ball_y=pad_y-ball_r
	ball_dx=1
	ball_dy=-1
	ball_ang=1
	chain=1
	sticky=true 
end

function setang(ang)
	ball_ang=ang
	if ang==2 then
		ball_dx=0.50*sign(ball_dx)
		ball_dy=1.30*sign(ball_dy)
	elseif ang==0 then
		ball_dx=1.30*sign(ball_dx)
		ball_dy=0.50*sign(ball_dy)
	else
		ball_dx=1*sign(ball_dx)
		ball_dy=1*sign(ball_dy)
	end
end

function sign(n)
 if n<0 then
  return -1
 elseif n>0 then
  return 1
 else
  return 0
 end
end

function gameover()
	mode="gameover" 
end

function levelover()
	mode="levelover" 
end

function update_gameover()
	if btnp(5) then
	 startgame()
	end
end

function update_levelover()
	if btnp(5) then
	 nextlevel()
	end
end

function update_game()
	local buttpress=false
	local next_x,next_y, brickhit
	
	if btn(0) then
		--left
		pad_dx=-2.5
		buttpress=true
		--pad_x-=4
		if sticky then
			ball_dx=-1
		end
	end
	if btn(1) then
	 -- right
	 pad_dx=2.5
	 buttpress=true
	 --pad_x+=4
	 if sticky then
		ball_dx=1
	end
	end
	if sticky and btnp(4) then
		sticky=false
	end
	if not(buttpress) then
		pad_dx=pad_dx/2.3
	end
	
	pad_x+=pad_dx
	pad_x=mid(0,pad_x,127-pad_w)
	
	if sticky then
		ball_x=pad_x+flr(pad_w/2)
		ball_y=pad_y-ball_r-1
	else
		-- regular ball physics
		next_x = ball_x+ball_dx
		next_y = ball_y+ball_dy

		if next_x > 124 or next_x < 3 then
			next_x=mid(0,next_x,127)
			ball_dx = -ball_dx
			sfx(0)
		end
		if next_y < 9 then
			next_y=mid(0,next_y,127)
			ball_dy = -ball_dy
			sfx(0)
		end
	
		-- check if ball hit paddle
		if ball_box(next_x,next_y,pad_x,pad_y,pad_w,pad_h)  then
	 		-- deal with collision
	 		-- find out in which direction to deflect
			if deflx_ballbox(ball_x,ball_y,ball_dx,ball_dy,pad_x,pad_y,pad_w,pad_h) then
				-- ball hit paddle on the side
				ball_dx = -ball_dx
				if ball_x < pad_x + (pad_w/2) then
					next_x = pad_x - ball_r
				else	
					next_x = pad_x + pad_w + ball_r
				end
			else
				-- ball hit paddle on the top/bottom
				ball_dy = -ball_dy
				if ball_y > pad_y then
					-- bottom
					next_y = pad_y + pad_h + ball_r
				else
					-- top
					nexty = pad_y-ball_r
					if abs(pad_dx)>2 then
						-- change angle
						if sign(pad_dx)==sign(ball_dx) then
							-- flatten angle
							setang(mid(0,ball_ang-1,2))
						else
							-- raise angle
							if ball_ang==2 then
								ball_dx=-ball_dx
							else
								setang(mid(0,ball_ang+1,2))
							end
						 end
					end
				end
			end	 
 			sfx(1)
				chain=1
		end
	
		brickhit=false
		for i=1,#brick_x do	
			-- check if ball hit brick
			if brick_v[i] and ball_box(next_x,next_y,brick_x[i],brick_y[i],brick_w,brick_h)  then
				-- deal with collision
				if not(brickhit) then
					-- find out in which direction to deflect
					if deflx_ballbox(ball_x,ball_y,ball_dx,ball_dy,brick_x[i],brick_y[i],brick_w,brick_h) then
						ball_dx = -ball_dx
					else
						ball_dy = -ball_dy
					end
				end
				brickhit=true
				hitbrick(i)

				if levelfinished() then
					levelover()
				end
			end
		end
		
		ball_x = next_x
		ball_y = next_y
 
		if next_y >127 then
			sfx(2)
			lives -= 1
			if lives<0 then
				_draw()
				gameover()
			end
			serveball()
		end 	
	end
end

function hitbrick(_i)
	if brick_t[_i]=="b" then
		sfx(2+chain)
		brick_v[i] = false
		points+=10*chain
		chain+=1
		chain = mid(1,chain,7)
	elseif brick_t[_i]=="i" then
		sfx(10)
	end
end

function _draw()
 if mode=="game" then
  draw_game()
 elseif mode=="start" then
 	draw_start()
 elseif mode=="gameover" then
		draw_gameover()
 elseif mode=="levelover" then
  draw_levelover()		
 end
end

function draw_start()
	cls()
	print("pico hero breakout",30,30,7)
	print("press ❎ to start",30,80,11)	
end

function draw_gameover()
	rectfill(0,60,128,76,0)
	print("game over",46,62,7)
	print("press ❎ to restart",27,68,6)
end

function draw_levelover()
	rectfill(0,60,128,76,0)
	print("stage clear!",46,62,7)
	print("press ❎ to continue",27,68,6)
end

function draw_game()
	local i
	cls(1)
	circfill(ball_x,ball_y,ball_r,10)
	if sticky then
		-- serve preview
		line(ball_x+ball_dx*4,ball_y+ball_dy*4,ball_x+ball_dx*10,ball_y+ball_dy*10,10)
	end
	
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,pad_c)
 
	--draw bricks
	for i=1,#brick_x do
		if brick_v[i] then
			if brick_t[i] == "b" then
				brickcol=14
			elseif brick_t[i] == "i" then
				brickcol=6
			elseif brick_t[i] == "h" then
				brickcol=15
			elseif brick_t[i] == "s" then
				brickcol=10
			elseif brick_t[i] == "p" then
				brickcol=12
			end
			rectfill(brick_x[i],brick_y[i],brick_x[i]+brick_w,brick_y[i]+brick_h,brickcol)
		end
	end
 
	rectfill(0,0,128,6,0)
	if debug!="" then
		print(debug,1,1,7)
	else
 	print("lives: "..lives,1,1,7)
		print("score: "..points,40,1,7)
		print("chain: "..chain.."x",90,1,7)
	end
end

function ball_box(bx,by,box_x,box_y,box_w,box_h)
	-- check for collision with ball and paddle
	if by-ball_r > box_y+box_h then return false end
	if by+ball_r < box_y then	return false end
	if bx-ball_r > box_x+box_w then	return false	end
	if bx+ball_r < box_x then	return false	end		
		
	return true
end

function deflx_ballbox(bx,by,bdx,bdy,tx,ty,tw,th)
    local slp = bdy / bdx
    local cx, cy
    if bdx == 0 then
        return false
    elseif bdy == 0 then
        return true
    elseif slp > 0 and bdx > 0 then
        cx = tx - bx
        cy = ty - by
        return cx > 0 and cy/cx < slp
    elseif slp < 0 and bdx > 0 then
        cx = tx - bx
        cy = ty + th - by
        return cx > 0 and cy/cx >= slp
    elseif slp > 0 and bdx < 0 then
        cx = tx + tw - bx
        cy = ty + th - by
        return cx < 0 and cy/cx <= slp
    else
        cx = tx + tw - bx
        cy = ty - by
        return cx < 0 and cy/cx >= slp
    end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001635016350163501634016320153101530015300143000e3000c3000c3000c3000c3000c3000b3000a3000730002300003000030024300273002730026300253000d3000e30010300113001130012300
000100000e3500e3500e3500f3500e3500e3501230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001d4501a4501845015450114500e4500a45006450024500045000450074000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002d3502e350303303032031310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003035031350323303232034310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003035032350353303632037310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000363503635037330373203b310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003635038350383303c3203d310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000363503c3503b3303c3203d310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003b3503b3503d3303e3203e310333000a60008600086000000000000000000000025700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003845034450344503445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
