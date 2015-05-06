# moves.rb
# The heart of twitfu! Moves are run when their method is called by an action. They determine the result of the action and update the models.

### MODELS AND MOVES
TotalHitPoints = 25

# Returns a number between 1 and 20
def roll_dice
	rand(20) + 1 
end

# Returns damage dealt and type based on base attack and a roll of the dice
def calculate_damage(base_attack)
	roll = roll_dice

	case roll
		when 1..3		
			result = "miss"
			mult = 0
		when 4..10		
			result = "graze"
			mult = 0.75
		when 11..19
			result = "hit"
			mult = 1	# hit
		when 20
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
		when 1..6
			result = "block"
			mult = 0.5

		when 7..20
			result = "fail"
			mult = 1
	end

	damage = (base_attack * mult).round
	return result, damage
end

module Moves
	# moves should have three aguments: fight, from, to
	# they should return a result that can be tweeted
	# every move's logic should be passed as a block to if_is_active,
	# so that a waiting or won fight can't be used improperly

	# register the moves in here to track their base attacks
	AttackPoints = {
		:hammerfist => 5,

	}

	# default action for missing methods
	def method_missing(method_name, *args, &block)
		return false # let the controller handle notifying the user
	end

	# every normal move should be wrapped in this so that it only runs if the fight is active
	def if_is_active(fight)
		# TODO: is there a better way of accomplishing what I'm trying to do here?
		if fight.status == "active"
			yield
		else
			return false
		end
	end
	
	# challenge a player to a match
	def challenge(fight, from, to)
		if fight.status == "inactive"
			fight.status = "waiting"
			fight.save
			return "#{to.user_name}: #{from.user_name} has challenged you! accept?"
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


			return "fight accepted. FIGHT!"

		end
	end


	def hammerfist(fight, from, to)
		if_is_active(fight) do
			base_attack = AttackPoints[:hammerfist]
			result, damage = calculate_damage base_attack

			to.fights_hp[fight.title] -= damage
			to_hp = to.fights_hp[fight.title]
			to.save
			return "#{from.user_name} hammerfists #{to.user_name}! #{result}, -#{damage}HP #{to_hp}/#{TotalHitPoints}"
		end
	end

	def block(fight, from, to)
		if_is_active(fight) do
			pending_move_type = fight.pending_move[:type]
			pending_move_base_attack = AttackPoints[pending_move_type.to_sym]

			result, damage = calculate_block pending_move_base_attack

			from.fights_hp[fight.title] -= damage
			from_hp = from.fights_hp[fight.title]
			from.save			

			if result == "block"
				return "#{from.user_name} blocks #{to.user_name}'s #{pending_move_type}; reduced to -#{damage}HP #{from_hp}/#{TotalHitPoints}"
			elsif result == "fail"
				return "#{from.user_name}'s block fails against #{to.user_name}'s #{pending_move_type}, hit, -#{damage}HP #{from_hp}/#{TotalHitPoints}"
			end
					
		end
	end


end