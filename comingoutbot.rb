#!/usr/bin/env ruby

require 'redis'
require_relative 'lib/comingout'

db = Redis.new
unless db.exists "#{Comingout::WIKI_DB}:1"
  Comingout::ParseWikipedia.new.parse
end
unless db.exists "#{Comingout::IMDB_DB}"
  Comingout::ParseImdb.new.parse
end
puts 'Starting bot'
Comingout::Bot.new.run
