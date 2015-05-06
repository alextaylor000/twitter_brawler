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

module Moves
	# moves should have three aguments: fight, from, to
	# they should return a result that can be tweeted
	# every move's logic should be passed as a block to if_is_active

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
			to.fights_hp[fight.title] 	= TotalHitPoints

			from.save
			to.save


			return "fight accepted. FIGHT!"

		end
	end


	def hammerfist(fight, from, to)
		if_is_active(fight) do
			base_attack = 5
			result, damage = calculate_damage base_attack

			to.fights_hp[fight.title] -= damage
			to_hp = to.fights_hp[fight.title]
			to.save
			return "#{from.user_name} hammerfists #{to.user_name}! #{result}, -#{damage}HP #{to_hp}/#{TotalHitPoints}"
		end
	end

	def block(fight, from, to)
		
	end


end