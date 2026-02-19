require 'gosu'
require 'opengl'
require 'glu'
require 'json'

OpenGL.load_lib; GLU.load_lib
include OpenGL, GLU

Dir.glob("lib/*.rb").each {|fn| require_relative(fn)}

Window.new.show
