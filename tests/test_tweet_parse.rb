tweet = "@twtfu @twtfu_user hammerfist asdf"
tweet2 = "@twtfu challenge @twtfu_user to a duel"

ta = tweet.split(" ")
@type = nil
ta.each do |t|
	next if t.include? "@"
	@type = t
	break # on the first non-mention
end
puts @type



