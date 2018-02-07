$LOAD_PATH << '.'

Bundler.require
require 'joyconf'

filename = ARGV[0]
puts Joyconf.new.compile File.open(filename).read
