require 'telegram/bot'
require_relative 'constants'
require_relative 'comingout_db'

module Comingout
  class Bot
    def initialize
      @db = Comingout::ComingoutDB.new
    end

    def run
      Comingout::ParseWikipedia.new(@db).parse
      Comingout::ParseRuWikipedia.new(@db).parse
      Comingout::ParseImdb.new(@db).parse
      puts 'Starting bot'

      Telegram::Bot::Client.run(Comingout::TELEGRAM_TOKEN) do |bot|
        bot.listen do |chat|
          cmd = chat.text
          case cmd
          when '/start'
            msg = "Hello, #{chat.from.first_name}!\n"
            msg << 'This bot is for finding out celebrities coming out.'
            say(bot, chat, msg)
          else
            dialog(bot, chat)
          end
        end
      end
    end

    private

    def dialog(bot, chat)
      chat_text = chat.text
      chat_text.gsub!(/[*?]/, '') # remove wildcard search
      found = @db.ferret.search(chat_text, limit: :all) # strict search
      max_score = found[:max_score]
      hits = found[:hits]
      return do_you_mean(bot, chat) if hits.empty?
      hits_max = []
      hits.each { |hit| hits_max << hit if hit[:score] == max_score }
      return one_hit(bot, chat, hits_max.first[:doc]) if hits_max.size == 1
      return five_hits(bot, chat, hits) if hits.size < 5
      muli_hits(bot, chat, hits)
    end

    def do_you_mean(bot, chat)
      chat_text = Comingout.translit(chat.text.downcase)
      found = @db.ferret.search("#{chat_text}~", limit: :all) # fuzzy search
      max_score = found[:max_score]
      hits = found[:hits]
      return say(bot, chat, 'Found no data') if hits.empty?
      hits_max = []
      hits.each { |hit| hits_max << hit if hit[:score] == max_score }
      if hits_max.size == 1
        return if one_hit_right?(bot, chat, hits_max.first[:doc])
      end
      return five_hits(bot, chat, hits) if hits.size < 5
      muli_hits(bot, chat, hits)
    end

    def one_hit(bot, chat, hit)
      doc = @db.ferret[hit]
      person = @db.get_by_index(doc[:id])
      say(bot, chat, comeout(person))
    end

    def one_hit_right?(bot, chat, hit)
      doc = @db.ferret[hit]
      person = @db.get_by_index(doc[:id])
      msg = "Do you mean <b>#{person['name']}?</b>"
      ans = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [%w[yes no]], one_time_keyboard: true
      )
      bot.api.send_message(chat_id: chat.chat.id, text: msg, reply_markup: ans,
                           parse_mode: 'HTML')
      response = ''
      bot.listen { |req| response = req.text; break }
      if %w[yes да].include?(response.downcase)
        say(bot, chat, comeout(person))
        true
      end
    end

    def five_hits(bot, chat, hits)
      names = []
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each do |db_index|
        doc = @db.ferret[db_index[:doc]]
        person = @db.get_by_index(doc[:id])
        names << person['name']
      end
      ans = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: names, one_time_keyboard: true
      )
      bot.api.send_message(chat_id: chat.chat.id, text: msg, reply_markup: ans)
    end

    def muli_hits(bot, chat, hits)
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each_with_index do |db_index, counter|
        doc = @db.ferret[db_index[:doc]]
        person = @db.get_by_index(doc[:id])
        msg << "#{counter + 1}. #{person['name']}\n"
      end
      say(bot, chat, msg)
    end

    def say(bot, chat, msg)
      bot.api.send_message(chat_id: chat.chat.id, text: msg, parse_mode: 'HTML')
    end

    def comeout(person)
      msg = "<a href='#{person['uri']}'>#{person['name']}</a>\n"
      msg << "<b>Coming out:</b> <i>#{person['note']}</i>"
    end
  end
end
