#!/usr/bin/env ruby
require 'redis'
require_relative 'lib/comingout'

db = Redis.new(url: ENV["REDIS_URL"]) # url added for heroku.com
Comingout::ParseWikipedia.new.parse unless db.exists Comingout::DB_WIKI
Comingout::ParseRuWikipedia.new.parse unless db.exists Comingout::DB_RU_WIKI
Comingout::ParseImdb.new.parse unless db.exists Comingout::DB_IMDB
puts 'Starting bot'
Comingout::Bot.new.run
