require 'redis'
require 'mechanize'

class ParseWikipedia
  WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze
  WIKI_LINKS = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'.freeze
  WIKI_DB = 'lgbt:wiki'.freeze

  def initialize
    @agent = Mechanize.new
    @db = Redis.new
    @index = 1
  end

  def run
    links = @agent.get(WIKI_PAGE).links_with(xpath: WIKI_LINKS)
    urls = links.map { |link| "https://en.wikipedia.org/wiki/#{link}" }
    urls.each do |url|
      print '.'
      page = @agent.get(url)
      parse_table(page)
    end
    puts "\n#{@index - 1} entries added"
  end

  private

  def parse_table(page)
    tr = page.xpath('//*[@id="mw-content-text"]/div/table/tr')
    tr.shift
    tr.each do |row|
      td = row.xpath('./td')
      next if td.size != 5
      name = td[0].xpath('.//a')
      ref = td[4].xpath('.//a/@href')
      path = "//*[@id=\"#{ref.text[1..-1]}\"]//span[@class=\"reference-text\"]"
      composite_name = name.text
      prime_names = composite_name.split(' ')
      ref_text = page.xpath(path)
      uri = "https://en.wikipedia.org#{name.xpath('@href')}"
      @db.hset "#{WIKI_DB}:#{@index}", 'name', composite_name
      @db.hset "#{WIKI_DB}:#{@index}", 'uri', uri
      @db.hset "#{WIKI_DB}:#{@index}", 'note', ref_text.to_s
      prime_names.each { |i| @db.rpush "#{WIKI_DB}:name:#{i.downcase}", @index }
      @index += 1
    end
  end
end
