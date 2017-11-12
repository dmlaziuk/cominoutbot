#!/usr/bin/env ruby
require 'redis'
require_relative 'lib/comingout'

Comingout::Bot.new.run
