# moves.rb
# The heart of twitfu! Moves are run when their method is called by an action. They determine the result of the action and update the models.

DebugMode = false # set this to true to short-circuit calculate_result

### MODELS AND MOVES
TotalHitPoints = 25

# Returns a number between 1 and 20
def roll_dice
	rand(20) + 1 
end

# Returns damage dealt and type based on base attack and a roll of the dice
def calculate_damage(base_attack, level=:basic)
	roll = roll_dice

	if level == :basic
		miss 	= 1..3
		graze 	= 4..10
		hit 	= 11..19
		crit 	= 20
	elsif level == :advanced
		miss 	= 1..8
		graze 	= 9..14
		hit 	= 15..9
		crit 	= 20
	end


	case roll
		when miss
			result = "Miss"
			mult = 0
		when graze
			result = "Graze"
			mult = 0.75
		when hit
			result = "Hit"
			mult = 1	# hit
		when crit
			result = "Critical hit"
			mult = 1.25 # critical hit!
	end

	damage = (base_attack * mult).round

	return result, damage
end


# Returns damage dealt when a move is blocked
def calculate_block(base_attack)
	roll = roll_dice

	case roll
		when 1..15
			result = "block"
			mult = 0.5

		when 16..20
			result = "fail"
			mult = 1
	end

	damage = (base_attack * mult).round
	return result, damage
end

module Moves
	# moves should have three aguments: fight, from, to
	# they should return a result that can be tweeted

	# register the moves in here to track their base attacks
	AttackPoints = {
		:challenge => nil,
		:accept => nil,
		:block => nil,

		# basic
		:kick => 5,
		:roundhouse => 5,
		:punch => 5,
		:jab => 5,
		:haymaker => 5,
		:hammerfist => 5,
		:palm_strike => 5,
		:uppercut => 5,

		# advanced
		:eagle_claw => 10,
		:skeleton_claw => 10,
		:butterfly_kick => 10,
		:thumb_strike => 10,
		:flying_kick => 10,
		:scorpion_kick => 10,
		:tornado_kick => 10
	}

	# challenge a player to a match
	def challenge(fight, from, to)
		if fight.status == "inactive"
			fight.status = "waiting"
			fight.save
			return one_of "@#{to.user_name}: @#{from.user_name} has questioned your honour and challenges you to a duel. Reply 'accept' to begin.", \
							"@#{to.user_name}: @#{from.user_name} has declared battle! Reply 'accept' to begin.", \
							"@#{to.user_name}: @#{from.user_name} curses your family's name and wishes to duel. Reply 'accept' to defend your honour."
		end

	end

	# accept a fighter's challenge
	def accept(fight, from, to) 
		if fight.status == "waiting" \
			and from.user_name == fight.challenged

			fight.status = "active"
			fight.save

			# add hp to the fighters for this specific fight
			from.fights_hp[fight.title] 	= TotalHitPoints
			to.fights_hp[fight.title] 		= TotalHitPoints

			from.save
			to.save

			return one_of "@#{from.user_name} and @#{to.user_name}: prepare for battle!", \
							"@#{from.user_name} and @#{to.user_name} are locked in combat!", \
							"@#{from.user_name} contemplates @#{to.user_name}'s destruction."

		end
	end

	def block(fight, from, to)

		pending_move_type = fight.pending_move[:type]
		pending_move_base_attack = AttackPoints[pending_move_type.to_sym]

		result, damage = calculate_block pending_move_base_attack

		from.fights_hp[fight.title] -= damage
		from_hp = from.fights_hp[fight.title]
		from.save			

		if result == "block"
			return one_of "@#{from.user_name} blocks @#{to.user_name}'s #{pending_move_type}; reduced to -#{damage}HP (#{from_hp}/#{TotalHitPoints})"
		elsif result == "fail"
			return one_of "@#{from.user_name}'s block fails vs @#{to.user_name}'s #{pending_move_type}, hit, -#{damage}HP (#{from_hp}/#{TotalHitPoints})"
		end

	end



	# OFFENSIVE MOVES ---- BASIC
	def kick(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		return one_of "@#{move[:from]} kicks @#{move[:to]}! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"		
	end

	def roundhouse(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		if move[:result] == "Miss"
			return one_of "@#{move[:to]} deftly avoids @#{move[:from]}'s roundhouse kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
							"@#{move[:to]} steps aside as @#{move[:from]}'s roundhouse kick strikes thin air. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} attacks @#{move[:to]} with a roundhouse kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} strikes @#{move[:to]} with a roundhouse kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"		
		end
		
	end

	def punch(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s punch is no match for @#{move[:to]}'s agility. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} throws a punch at @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} punches @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
						  "@#{move[:from]}'s punch dazes @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"

		end
	end

	def jab(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		return one_of "@#{move[:from]} jabs @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
						"En garde - @#{move[:from]} jabs @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
	end

	def haymaker(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s haymaker misses @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]}'s haymaker proves useless against @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"

		elsif move[:result] == "Critical hit"
			return one_of "@#{move[:from]}'s haymaker punch reduces @#{move[:to]} to tears. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
			
		else
			return one_of "@#{move[:from]} desperately swipes at @#{move[:to]} with a haymaker punch. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
				"@#{move[:from]} stuns @#{move[:to]} with a haymaker punch to the chin. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"

		end
				
		
	end

	def hammerfist(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]} is not yet skilled in the hammerfist against @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]}'s hammerfist strikes @#{move[:to]}! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
		

	end

	def palm_strike(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		return one_of "@#{move[:from]}'s palm strike wallops @#{move[:to]}! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
						"HAYYAAA! @#{move[:from]} attacks @#{move[:to]} with palm strike! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
	end

	def uppercut(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s uppercut against @#{move[:to]} lacks style. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
					"@#{move[:to]} shows great skill and avoids @#{move[:from]}'s uppercut. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"

		else

			return one_of "@#{move[:from]}'s uppercut strikes @#{move[:to]}! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
					"@#{move[:from]} springs forth and uppercuts @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
	end

	# OFFENSIVE MOVES ---- ADVANCED
	def eagle_claw(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s eagle claw is useless against @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		elsif move[:result] == "Critical hit"
			return one_of "Magnificent. @#{move[:to]} becomes prey for @#{move[:from]}'s eagle claw. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
			
		else
			return one_of "@#{move[:from]} lunges at @#{move[:to]} with eagle claw! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} attacks @#{move[:to]} with eagle claw! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
		
	end

	def skeleton_claw(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]} merely pokes @#{move[:to]} with skeleton claw. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		elsif move[:result] == "Critical hit"
			return one_of "@#{move[:from]} masters the skeleton claw, strikes @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} devastates @#{move[:to]} with skeleton claw. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} attacks with skeleton claw, strikes @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
				
		
	end

	def butterfly_kick(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s butterfly kick against @#{move[:to]} lacks grace. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} flies towards @#{move[:to]} in butterfly kick stance. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} attacks @#{move[:to]} with butterfly kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end

		
	end

	def thumb_strike(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)

		return one_of "@#{move[:from]} attacks @#{move[:to]} with thumb strike. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})", \
					"@#{move[:from]} shows no mercy against @#{move[:to]} with thumb strike. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
	end

	def flying_kick(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "Despicable! @#{move[:from]}'s flying kick misses @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} attacks @#{move[:to]} with flying kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"@#{move[:from]} strikes @#{move[:to]} with a flying kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
		
	end

	def scorpion_kick(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]}'s scorpion kick scuttles past @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]} stings @#{move[:to]} with scorpion kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})",
							"Impressive. @#{move[:from]}'s scorpion kick strikes @#{move[:to]}. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
	end

	def tornado_kick(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :advanced)
		if move[:result] == "Miss"
			return one_of "@#{move[:from]} fails to wound @#{move[:to]} with tornado kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		else
			return one_of "@#{move[:from]}'s blurry form devastates @#{move[:to]} with tornado kick. #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		end
		
	end
	

	# only called directly by Action when a fight has resolved
	def win(fight, from, to, winner)
		challenger_hp = from.fights_hp[@fight.title]
		challenged_hp = to.fights_hp[@fight.title]

		return one_of "@#{winner} emerges victorious! Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}", \
			"A display of genius! @#{winner} is the victor. Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}",
			"So then, you've mastered it. @#{winner} has triumphed. Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}",
			"You are most skilled. @#{winner} is the victor. Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}",
			"You training is complete. @#{winner} has triumphed. Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}"
	end

	private
			# Calculate result, apply damage, and return values needed to compose tweet.
			def calculate_result(fight, from, to, move, level)
				return calculate_result_debug_mode if DebugMode

				base_attack = AttackPoints[move]
				result, damage = calculate_damage base_attack, level
				apply_damage(to, damage)
				to_hp = to.fights_hp[fight.title]
				to.save

				return { 	:from => from.user_name, \
							:to => to.user_name, \
							:result => result, \
							:damage => damage, \
							:to_hp => to_hp }
			end

			# calculate a fake result; used for testing the lengths of all the tweets
			def calculate_result_debug_mode
				return { 	:from => "user1__________", \
							:to => "user2__________", \
							:result => one_of("Miss", "Graze", "Hit", "Critical hit"), \
							:damage => "16", \
							:to_hp => "21" }

			end

			# applies damage or makes HP 0
			def apply_damage(target, amount)
				if amount > target.fights_hp[fight.title]
					target.fights_hp[fight.title] = 0
				else
					target.fights_hp[fight.title] -= amount
				end

				target.save
			end

			# default action for missing methods
			def method_missing(method_name, *args, &block)
				return false # let the controller handle notifying the user
			end

			# every normal move should be wrapped in this so that it only runs if the fight is active
			# MOVED THIS INTO ACTION.RB
			# def if_is_active(fight)
			# 	# TODO: is there a better way of accomplishing what I'm trying to do here?
			# 	if fight.status == "active"
			# 		yield

			# 	else
			# 		return false
			# 	end
			# end
			
			# Return a random string, for keeping things interesting
			def one_of(*text)
				string = text[rand(text.count)]

				if string.length > 105
					debug "WARNING: Tweet is #{string.length} characters: '#{string}'"
				else
					#debug "tweet length: #{string.length}/140: #{string}"
				end

				return string
			end

end