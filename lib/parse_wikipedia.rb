require 'json'
require 'redis'
require 'mechanize'

class ParseWikipedia
  WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze
  WIKI_LINKS = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'.freeze
  WIKI_TABLE = '//*[@id="mw-content-text"]/div/table[2]/tr'.freeze
  ACTORS = 'actors:wiki'.freeze

  def initialize
    @agent = Mechanize.new
    @db = Redis.new
  end

  def run
    links = @agent.get(WIKI_PAGE).links_with(xpath: WIKI_LINKS)
    page = @agent.get('https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_A&action=edit')
    txt =  page.css('#wpTextbox1').text
    txt = txt.split('{| class="wikitable sortable"').last
    txt = txt.split('|}').first
    txt = txt.split('|- valign="top"').last
    txt = txt.split("|-\n")
    txt.each(&:strip!)
    txt.each_with_index do |item, index|
      arr = item.split("\n")
      next if arr[0].nil?
      arr[0].gsub!('{', '')
      arr[0].gsub!('}', '')
      arr[0].gsub!('[', '')
      arr[0].gsub!(']', '')
      arr[0].gsub!('sortname|', '')
      arr[0].gsub!('sort|', '')
      names = arr[0][2..-1].split('|')
      print "#{index}: "
      names.each_with_index do |item, index|
        item.gsub!(/\(.*?\)/, '')
        item.strip!
        print "[#{index}]#{item}"
      end
      puts "|\n"
    end
  end
end
