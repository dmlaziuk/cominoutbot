require 'json'
require 'redis'
require 'mechanize'

class ParseWikipedia
  WIKI_PAGE = 'https://en.wikipedia.org/wiki/List_of_gay,_lesbian_or_bisexual_people'.freeze
  WIKI_LINKS = '//*[@id="mw-content-text"]/div/div[3]/ul/li/a'.freeze
  WIKI_QUERY = 'https://en.wikipedia.org/w/api.php?action=query&format=json&formatversion=2&prop=revisions&rvprop=content&titles='.freeze
  ACTORS = 'actors:wiki'.freeze

  def initialize
    @agent = Mechanize.new
    @db = Redis.new
  end

  def run
    links = @agent.get(WIKI_PAGE).links_with(xpath: WIKI_LINKS)
    hrefs = links.map { |link| link.href[6..-1] }
    ll = WIKI_QUERY + hrefs.join('|')
    data = JSON.parse(@agent.get(ll).content)
    text = data['query']['pages'].map { |p| p['revisions'].first['content'] }
    puts text
  end
end
