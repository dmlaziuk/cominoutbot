require 'json'
require 'redis'
require 'mechanize'

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

  def parse(textbox)
    first_name = []
    surname = []
    is_composite_name = ->(name) { name.include?(' ') || name.include?(',') }
    is_simple_name = ->(name) { !name.include?(' ') && !name.include?(',') }
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

    txt = textbox.split /^\|-[^\n]*?\n/
    txt.shift
    #txt.shift if txt.first.include?('style=')
    #txt.each_with_index { |item, index| puts "#{index}: #{item}" }
    txt.each(&:strip!)
    txt.each_with_index do |item, index|
      next if item.include?('style=')
      #i = item.index /\|}\n/
      #i = -1 if i.nil?
      #arr = item[0..i].split("\n")
      arr = item.split("\n")
      names = arr[0]
      lifetime = arr[1]
      nationality = arr[2]
      notable = arr[3]
      notes = arr[4]
      next if names.nil?
      names.gsub!('{', '')
      names.gsub!('}', '')
      names.gsub!('[', '')
      names.gsub!(']', '')
      names.gsub!('sortname|', '')
      names.gsub!('sort|', '')
      names = names[2..-1]
      next if names.nil?
      puts "#{index}: #{names}"
      puts "#{index}:NIL" if names.nil?
      names = names.split('|')
      names.map! do |name|
        new_name = name.gsub(/\(.*?\)/, '')
        new_name = new_name.gsub(/<.*?>/, '')
        new_name = new_name.strip
        new_name = nil if new_name.include?('=') || new_name == ''
        new_name
      end
      names.compact!
      first_name = []
      surname = []
      case names.size
        when 1
          surname << names.first
        when 2
          if is_simple_name[names.first] && is_simple_name[names.last]
            first_name << names.first
            surname << names.last
          else
            if is_simple_name[names.last]
              first_name << names.first
              surname << names.last
            else
              first_name << names.last
              surname << names.first
            end
          end
        when 3
          first_name << names[0]
          surname << names[1]
          first_name << names[2]
        else # >= 4 names
          first_name << names[0]
          surname << names[1]
          first_name << names[2]
          first_name << names[3]
      end
      parse_first_name = first_name.join(' ')
      parse_first_name.gsub!(',', ' ')
      parse_first_name.gsub!('  ', ' ')
      parse_first_name = parse_first_name.split(' ')
      parse_first_name.uniq!
      parse_surname = surname.join(' ')
      parse_surname.gsub!(',', ' ')
      parse_surname.gsub!('  ', ' ')
      parse_surname = parse_surname.split(' ')
      parse_surname.uniq!
      parse_first_name = parse_first_name - parse_surname
      parse_first_name = parse_first_name.join(' ')
      parse_surname = parse_surname.join(' ')
      #first_name.uniq!
      #first_name.map! {|name| name unless name == ''}
      #first_name.compact!
      #surname.uniq!
      #surname.map! {|name| name unless name == ''}
      #surname.compact!
      puts "name: #{parse_first_name}"
      puts "surname: #{parse_surname}"
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
