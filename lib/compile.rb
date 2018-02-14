$LOAD_PATH << '.'

Bundler.require
require 'lib/joyconf'

filename = ARGV[0]
puts Joyconf.new.compile File.open(filename).read
