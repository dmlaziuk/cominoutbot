require 'redis'
require 'mechanize'

module Comingout
  IMDB_DB = 'lgbt:imdb'.freeze

  class ParseImdb
    IMDB_PAGE = 'http://www.imdb.com/list/ls072706884/'.freeze

    def initialize
      @agent = Mechanize.new
      @db = Redis.new
    end

    def parse
      print 'Parsing IMDB.com '
      page = @agent.get(IMDB_PAGE)
      print '.'
      actors = page.css('.info').map {|item| item.text.strip.split("\n").first}
      count = @db.sadd(Comingout::IMDB_DB, actors)
      puts "\n#{count} entries added"
    end
  end

end
