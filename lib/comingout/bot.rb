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

    def say(bot, chat, msg)
      bot.api.send_message(chat_id: chat.chat.id, text: msg, parse_mode: 'HTML')
    end

    def ask(bot, chat, msg, ans)
      bot.api.send_message(chat_id: chat.chat.id, text: msg, reply_markup: ans,
                           parse_mode: 'HTML')
      response = ''
      bot.listen { |req| response = req.text; break }
      response
    end

    def do_you_mean(bot, chat)
      chat_text = Comingout.translit(chat.text.downcase)
      found = @db.ferret.search("#{chat_text}~", limit: :all) # fuzzy search
      max_score = found[:max_score]
      hits = found[:hits]
      if hits.empty?
        say(bot, chat, 'Found no data')
        return
      end
      hits_max = []
      hits.each { |item| hits_max << item if item[:score] == max_score }
      if hits_max.size == 1
        doc = @db.ferret[hits_max.first[:doc]]
        person = @db.get_by_index(doc[:id])
        question = "Do you mean <b>#{person['name']}?</b>"
        answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [%w[yes no]], one_time_keyboard: true
        )
        response = ask(bot, chat, question, answers)
        if %w[yes да].include?(response.downcase)
          say(bot, chat, comeout(person))
          return
        end
      end
      if hits.size < 5
        five_hits(bot, chat, hits)
        return
      end
      muli_hits(bot, chat, hits)
    end

    def dialog(bot, chat)
      chat_text = chat.text
      chat_text.gsub!(/[*?]/, '') # remove wildcard search
      found = @db.ferret.search(chat_text, limit: :all) # strict search
      max_score = found[:max_score]
      hits = found[:hits]
      return do_you_mean(bot, chat) if hits.empty?
      hits_max = []
      hits.each { |item| hits_max << item if item[:score] == max_score }
      if hits_max.size == 1
        one_hit(bot, chat, hits_max.first[:doc])
        return
      end
      if hits.size < 5
        five_hits(bot, chat, hits)
        return
      end
      muli_hits(bot, chat, hits)
    end

    def one_hit(bot, chat, hit)
      doc = @db.ferret[hit]
      person = @db.get_by_index(doc[:id])
      say(bot, chat, comeout(person))
    end

    def five_hits(bot, chat, hits)
      arr = []
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each do |db_index|
        doc = @db.ferret[db_index[:doc]]
        person = @db.get_by_index(doc[:id])
        arr << person['name']
      end
      ans = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: arr, one_time_keyboard: true
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

    def comeout(person)
      msg = "<a href='#{person['uri']}'>#{person['name']}</a>\n"
      msg << "<b>Coming out:</b> <i>#{person['note']}</i>"
    end
  end
end
