require 'redis'
require 'mechanize'
require 'wikicloth'

class ParseWikipedia
  WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze
  WIKI_LINKS = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'.freeze
  ACTORS = 'actors:wiki'.freeze
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_A&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_Ba–Bh&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_Bi–Bz&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_C&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_D–E&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_F&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_G&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_H&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_I–J&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_K&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_L&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_M&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_N–O&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_P–Q&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_R&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_Sa–Sc&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_Sd–Si&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_Sj–Sz&action=edit'
  #TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_T–V&action=edit'
  TEST_PAGE = 'https://en.wikipedia.org/w/index.php?title=List_of_gay,_lesbian_or_bisexual_people:_W–Z&action=edit'

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

  def parse(wikitext)

    txt = wikitext.split /^\|-[^\n]*?\n/
    txt.shift
    #txt.each_with_index { |item, index| puts "#{index}: #{item}" }
    txt.each(&:strip!)
    txt.each_with_index do |item, index|
      next if item.include?('style=')
      arr = item.split("\n")
      next if arr.empty?
      names = arr[0][2..-1]
      puts "#{index}: #{names}"
      next if names.nil?
      lifetime = arr[1][2..-1]
      nationality = arr[2][2..-1]
      notable = arr[3][2..-1]
      notes = arr[4][3..-1]
      names.gsub!(/\(.*?\)/, ' ')
      names.gsub!(/<.*?>/, ' ')
      names = names.scan /[^|]+/
      names.map! do |name|
        item = name.scan /[^\s\[\]{}]+/
        item -= %w[sort sortname]
        item.join(' ') if item.any?
      end
      names.compact!
      next if names.empty?
      first_name, surname = parse_names(names)
      puts "name: #{first_name}"
      puts "surname: #{surname}"
      puts "lifetime: #{lifetime}"
      puts "nationality: #{nationality}"
      puts "notable: #{notable}"
      puts "notes: #{notes}"
      puts 'HTML:'
      puts WikiCloth::Parser.new(data: notes).to_html(noedit: true)
      puts "\n"
    end
  end

  def parse_names(arr)
    first_name = []
    surname = []
    is_simple_name = ->(name) { !name.include?(' ') && !name.include?(',') }
    parse_two_names = lambda do |names|
      if is_simple_name[names[0]] && is_simple_name[names[1]]
        first_name << names[0]
        surname << names[1]
      else
        if is_simple_name[names[1]]
          first_name << names[0]
          surname << names[1]
        else
          first_name << names[1]
          surname << names[0]
        end
      end
    end

    names = arr
    names.map! do |name|
      if name.include?('=') || name == ''
        nil
      else
        name
      end
    end
    names.compact!
    first_name = []
    surname = []
    case names.size
      when 1
        surname << names.first
      when 2
        parse_two_names[names]
      when 3
        parse_two_names[names]
        first_name << names[2]
      else # >= 4 names
        parse_two_names[names]
        first_name << names[2]
        first_name << names[3]
    end
    # remove duplicates from first_name
    first_name = first_name.join(' ')
    first_name.gsub!(',', ' ')
    first_name.gsub!('  ', ' ')
    first_name = first_name.split(' ')
    first_name.uniq!
    surname = surname.join(' ')
    surname.gsub!(',', ' ')
    surname.gsub!('  ', ' ')
    surname = surname.split(' ')
    surname.uniq!
    first_name = first_name - surname
    first_name = first_name.join(' ')
    surname = surname.join(' ')
    [first_name, surname]
  end
end
