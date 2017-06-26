#there's gonna be trailing space, some debugger statements left in
require 'pry'

# this example method can take a hash as an arg and prints out the value for the "down" key
def testing_method(stuff)
	puts stuff["down"]

	binding.pry

	the_ending = "can't be reached bc of the above pry message"
end







