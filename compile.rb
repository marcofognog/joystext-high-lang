$LOAD_PATH << '.'
require 'joyconf'

filename = ARGV[0]
puts Joyconf.compile File.open(filename).read
