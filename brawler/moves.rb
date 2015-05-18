# moves.rb
# The heart of twitfu! Moves are run when their method is called by an action. They determine the result of the action and update the models.

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
			result = "miss"
			mult = 0
		when graze
			result = "graze"
			mult = 0.75
		when hit
			result = "hit"
			mult = 1	# hit
		when crit
			result = "critical"
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
			return one_of "@#{to.user_name}: @#{from.user_name} wishes to engage you in glorious combat. Reply 'accept' to begin.", \
							"@#{to.user_name}: @#{from.user_name} has declared battle! Reply 'accept' to begin.", \
							"@#{to.user_name}: @#{from.user_name} challenges you to a duel. Reply 'accept' to begin."
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


	def kick(fight, from, to)
		base_attack = AttackPoints[:kick]
		result, damage = calculate_damage base_attack, :basic
		apply_damage(to, damage)
		to_hp = to.fights_hp[fight.title]
		to.save
		return one_of "@#{from.user_name}'s kick strikes @#{to.user_name}! #{result}, -#{damage}HP (#{to_hp}/#{TotalHitPoints})"		
	end

	def palm_strike(fight, from, to)
		base_attack = AttackPoints[:palm_strike]
		result, damage = calculate_damage base_attack

		apply_damage(to, damage)
		to_hp = to.fights_hp[fight.title]
		to.save
		return one_of "@#{from.user_name}'s palm strike lands on @#{to.user_name}! #{result}, -#{damage}HP (#{to_hp}/#{TotalHitPoints})"				
	end

	def hammerfist(fight, from, to)
		move = calculate_result(fight, from, to, __method__.to_sym, :basic)
		return one_of "@#{move[:from]}'s hammerfist strikes @#{move[:to]}! #{move[:result]}, -#{move[:damage]}HP (#{move[:to_hp]}/#{TotalHitPoints})"
		#return one_of "@#{from.user_name}'s hammerfist strikes @#{to.user_name}! #{result}, -#{damage}HP (#{to_hp}/#{TotalHitPoints})"

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

	# only called directly by Action when a fight has resolved
	def win(fight, from, to, winner)
		challenger_hp = from.fights_hp[@fight.title]
		challenged_hp = to.fights_hp[@fight.title]

		return one_of "@#{winner} emerges victorious! Results: @#{fight.challenger} #{challenger_hp}/#{TotalHitPoints}  •  @#{fight.challenged} #{challenged_hp}/#{TotalHitPoints}"
	end

	private
			# Calculate result, apply damage, and return values needed to compose tweet.
			def calculate_result(fight, from, to, move, level)
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

				if string.length > 140
					debug "WARNING: Tweet is #{string.length} characters: '#{string}'"
				else
					debug "tweet length: #{string.length}/140"
				end

				return string
			end

end