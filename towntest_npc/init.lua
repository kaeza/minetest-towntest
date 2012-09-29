--[[

Towntest for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-towntest
License: GPLv3

NPCs

]]--


minetest.register_entity("towntest_npc:builder", {
	hp_max = 1,
	physical = false,
	collisionbox = {-0.4, -1, -0.4, 0.4, 1, 0.4},
	visual = "upright_sprite",
	visual_size = {x=1, y=2},
	textures = {"towntest_npc_builder.png", "towntest_npc_builder_back.png"},
	makes_footstep_sound = true,

	target = nil,
	speed = nil,
	after = nil,
	after_param = nil,
	
	get_staticdata = function(self)
		-- record current game
		return minetest.serialize({game_id=towntest.game_id,chestpos=self.chestpos})
	end,

	on_activate = function(self, staticdata)
		local data = minetest.deserialize(staticdata)
		-- save chestpos
		if not self.chestpos then
			if data and data.chestpos then
				self.chestpos = data.chestpos
			else
				self.chestpos = self.object:getpos()
			end
		end
	end,
	
	on_punch = function(self)
		-- remove npc from the list of npcs when they die
		if self.object:get_hp() <= 0 and self.chestpos then
			towntest_chest.npc[self.chestpos.x..","..self.chestpos.y..","..self.chestpos.z] = nil
		end
	end,

	on_step = function(self, dtime)

		-- moveto
		if self.target and self.speed then
			local s = self.object:getpos()
			local t = self.target
			local diff = {x=t.x-s.x, y=t.y-s.y, z=t.z-s.z}

			local yaw = math.atan(diff.z/diff.x)+math.pi/2
			if diff.z ~= 0 or diff.x > 0 then
				yaw = yaw+math.pi
			end
			self.object:setyaw(yaw) -- turn and look in given direction

			local amount = (diff.x^2+diff.y^2+diff.z^2)^0.5
			local v = self.speed
			local vec = {x=0, y=0, z=0}
			vec.x = diff.x*v/amount
			vec.y = diff.y*v/amount
			vec.z = diff.z*v/amount
			self.object:setvelocity(vec) -- walk in given direction

			if math.abs(diff.x) < self.range and math.abs(diff.y) < self.range and math.abs(diff.z) < self.range then
				self.object:setvelocity({x=0, y=0, z=0})
				self.target = nil
				self.speed = nil
				if self.after then
					self.after(self, self.after_param) -- after they arrive
				end
			end
			
		-- idle
		else
			-- look around
			if math.random(50) == 1 then
				self.object:setyaw(self.object:getyaw()+((math.random(0,360)-180)/180*math.pi))
			end
		end
		
	end,

	-- API
	-- self: the lua entity
	-- pos: the position to move to
	-- range: the distance within pos the npc will go to
	-- speed: the speed at which the npc will move
	-- after: callback function(self) which is triggered when the npc gets within range of pos
	moveto = function(self, pos, range, speed, after, after_param)
		self.target = pos
		self.speed = speed
		self.after = after
		self.after_param = after_param
		self.range = range
		if self.range < 0.1 then self.range = 0.1 end
	end
})