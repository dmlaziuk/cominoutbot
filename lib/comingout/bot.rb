require 'set'
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
            say(bot, chat, dialog(bot, chat))
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
    end

    def do_you_mean(bot, chat)
      chat_text = Comingout.translit(chat.text.downcase)
      found = @db.ferret.search("#{chat_text}~", limit: :all) # fuzzy search
      max_score = found[:max_score]
      hits = found[:hits]
      return 'Found no data' if hits.empty?
      hits_max = []
      hits.each { |item| hits_max << item if item[:score] == max_score }
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each_with_index do |db_index, counter|
        doc = @db.ferret[db_index[:doc]]
        person = @db.get_by_index(doc[:id])
        msg << "#{counter + 1}. #{person['name']}\n"
      end
      if hits_max.size == 1
        doc = @db.ferret[hits_max.first[:doc]]
        person = @db.get_by_index(doc[:id])
        question = "Do you mean <b>#{person['name']}?</b>"
        answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [%w[yes no]], one_time_keyboard: true
        )
        ask(bot, chat, question, answers)
        response = ''
        bot.listen { |req| response = req.text; break }
        msg = comeout(person) if %w[yes да].include?(response.downcase)
      end
      msg
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
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each_with_index do |db_index, counter|
        doc = @db.ferret[db_index[:doc]]
        person = @db.get_by_index(doc[:id])
        msg << "#{counter + 1}. #{person['name']}\n"
      end
      if hits_max.size == 1
        doc = @db.ferret[hits_max.first[:doc]]
        person = @db.get_by_index(doc[:id])
        msg = comeout(person)
      end
      msg
    end

    def comeout(person)
      msg = "<a href='#{person['uri']}'>#{person['name']}</a>\n"
      msg << "<b>Coming out:</b> <i>#{person['note']}</i>"
    end
  end
end
