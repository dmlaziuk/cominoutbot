require 'mechanize'
require_relative 'constants'
require_relative 'comingout_db'

module Comingout

  class ParseImdb

    IMDB_PAGE = 'http://www.imdb.com/list/ls072706884/'.freeze

    def initialize
      @agent = Mechanize.new
      @db = Comingout::ComingoutDB.new
    end

    def parse
      count = 0
      total_count = 0
      print 'Parsing IMDB.com '
      page = @agent.get(IMDB_PAGE)
      print '.'
      info = page.xpath('//*[@id="main"]/div/div[7]/div')
      info.each do |item|
        name = item.xpath('./div[3]/b').text
        uri = item.xpath('./div[3]/b/a/@href').text
        uri = "http://www.imdb.com#{uri}"
        note = item.xpath('./div[4]').text
        count += 1 if @db.addnx(name, uri, note)
        total_count += 1
      end
      @db.redis.set Comingout::DB_IMDB, 1 # flag
      @db.close
      puts "\n#{count} entries added out of #{total_count}"
    end
  end
end
