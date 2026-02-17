require 'gosu'

Dir.glob("lib/*.rb").each {|fn| require_relative(fn)}

Window.new.show
