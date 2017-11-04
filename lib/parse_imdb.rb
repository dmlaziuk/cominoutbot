require 'redis'
require 'mechanize'

class ParseImdb
  IMDB_PAGE = 'http://www.imdb.com/list/ls072706884/'.freeze
  ACTORS = 'actors:imdb'.freeze

  def initialize
    @agent = Mechanize.new
    @db = Redis.new
  end

  def run
    page = @agent.get(IMDB_PAGE)
    actors = page.css('.info').map { |item| item.text.strip.split("\n").first }
    @db.sadd(ACTORS, actors)
  end
end
