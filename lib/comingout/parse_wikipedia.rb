require 'redis'
require 'mechanize'
require 'ferret'
require_relative 'constants'

module Comingout
  class ParseWikipedia
    WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze

    def initialize
      @agent = Mechanize.new
      @db = Redis.new
      @index = 0
    end

    def parse
      print 'Parsing en.wikipedia.org '
      @ferret = Ferret::I.new(path: 'lgbt-wiki', key: :id)
      path = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'
      links = @agent.get(WIKI_PAGE).links_with(xpath: path)
      urls = links.map { |link| "https://en.wikipedia.org/wiki/#{link}" }
      urls.each do |url|
        print '.'
        page = @agent.get(url)
        parse_table(page)
      end
      @ferret.optimize
      @ferret.close
      puts "\n#{@index} entries added"
    end

    private

    def parse_table(page)
      tr = page.xpath('//*[@id="mw-content-text"]/div/table/tr')
      tr.shift
      tr.each do |row|
        td = row.xpath('./td')
        next if td.size != 5 # duct tape for error in "Z" table
        name = td[0].xpath('.//a')
        composite_name = name.text
        prime_names = composite_name.split(' ')
        ref = td[4].xpath('.//a/@href')
        ref_path = "//*[@id=\"#{ref.text[1..-1]}\"]//span[@class=\"reference-text\"]"
        ref_text = page.xpath(ref_path).text
        uri = "https://en.wikipedia.org#{name.xpath('@href')}"
        @db.hset "#{Comingout::WIKI_DB}:#{@index}", 'name', composite_name
        @db.hset "#{Comingout::WIKI_DB}:#{@index}", 'uri', uri
        @db.hset "#{Comingout::WIKI_DB}:#{@index}", 'note', ref_text
        prime_names.each do |name|
          @db.rpush "#{Comingout::WIKI_DB}:name:#{name.downcase}", @index
        end
        @ferret << { id: @index, name: composite_name }
        @index += 1
      end
    end
  end
end
