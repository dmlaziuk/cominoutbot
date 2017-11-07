require 'json'
require 'redis'
require 'mechanize'

class ParseWikipedia
  WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze
  WIKI_LINKS = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'.freeze
  ACTORS = 'actors:wiki'.freeze
  TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_A&action=edit'.freeze

  def initialize
    @agent = Mechanize.new
    @db = Redis.new
  end

  def run
    links = @agent.get(WIKI_PAGE).links_with(xpath: WIKI_LINKS)
    urls = links.map {|link| "https://en.wikipedia.org/w/index.php?title=#{link.uri.to_s[6..-1]}&action=edit" }
    urls.each do |url|
      page = @agent.get(url)
      parse(page.css('#wpTextbox1').text)
    end
  end

  def test
    parse(@agent.get(TEST_PAGE).css('#wpTextbox1').text)
  end

  private

  def parse(txt)
    first_name = []
    surname = []
    is_composite_name = ->(name) { name.include?(' ') || name.include?(',') }
    composite_or_surname = lambda do |name|
      if is_composite_name[name]
        nm, sn = parse_composite_name(name)
        first_name << nm
        surname << sn
      else
        surname << name
      end
    end
    composite_or_first_name = lambda do |name|
      if is_composite_name[name]
        nm, sn = parse_composite_name(name)
        first_name << nm
        surname << sn
      else
        first_name << name
      end
    end

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
      puts "#{index}: #{arr[0][2..-1]}"
      names.each do |name|
        # remove (*)
        name.gsub!(/\(.*?\)/, '')
        name.strip!
      end
      first_name = []
      surname = []
      case names.size
        when 1
          composite_or_surname[names.first]
        when 2
          first_name << names.first
          composite_or_surname[names.last]
        when 3
          first_name << names[0]
          surname << names [1]
          composite_or_first_name[names[2]]
        else # >= 4 names
          first_name << names[0]
          surname << names [1]
          composite_or_first_name[names[2]]
          composite_or_first_name[names[3]]
      end
      first_name.uniq!
      first_name.map! {|name| name unless name == ''}
      first_name.compact!
      surname.uniq!
      surname.map! {|name| name unless name == ''}
      surname.compact!
      puts "name: #{first_name}"
      puts "surname: #{surname}"
      puts "\n"
    end

  end

  def parse_composite_name(name)
    if name.include?(',')
      composite_name = name.split(',')
      return [composite_name.last.strip!, composite_name.first.strip]
    end
    composite_name = name.split(' ')
    return [composite_name.first, composite_name.last]
  end
end
