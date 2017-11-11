require 'set'
require 'ferret'
require 'telegram/bot'
require_relative 'constants'

module Comingout
  class Bot

    def initialize
      @db = Redis.new
      @ferret = Ferret::I.new(path: Comingout::FERRET)
    end

    def run
      Telegram::Bot::Client.run(Comingout::TELEGRAM_TOKEN) do |bot|
        bot.listen do |chat|
          msg = dialog(bot, chat)
          say(bot, chat, msg)
        end
      end
    end

    private

    def say(bot, chat, msg)
      bot.api.send_message(chat_id: chat.chat.id, text: msg, parse_mode: 'HTML')
    end

    def do_you_mean(bot, chat)
      chat_text = Comingout.translit(chat.text.downcase)
      chat_text.gsub! /[*?]/, '' # remove wildcards search
      found = @ferret.search("#{chat_text}~") # fuzzy search
      max_score = found[:max_score]
      hits = found[:hits]
      return 'Found no data' if hits.empty?
      hits_max = []
      hits.each { |item| hits_max << item if item[:score] == max_score }
      msg = "There are #{hits.size} persons with given name:\n"
      hits.each_with_index do |db_index, counter|
        doc = @ferret[db_index[:doc]]
        person = @db.hgetall "#{Comingout::WIKI_DB}:#{doc[:id]}"
        msg << "#{counter + 1}. #{person['name']}\n"
      end
      if hits_max.size == 1
        doc = @ferret[hits_max.first[:doc]]
        person = @db.hgetall "#{Comingout::WIKI_DB}:#{doc[:id]}"
        say(bot, chat, "Do you mean <b>#{person['name']}?</b>")
        bot.listen do |request|
          if %w[yes да].include?(request.text.downcase)
            msg = "<a href='#{person['uri']}'>#{person['name']}</a>\n"
            msg << "<b>Coming out:</b> <i>#{person['note']}</i>"
          end
          break
        end
      end
      msg
    end

    def dialog(bot, chat)
      chat_text = chat.text.downcase
      commands = chat_text.split(' ')
      lists = commands.map do |word|
        Set.new @db.lrange "#{Comingout::WIKI_DB}:name:#{word}", 0, -1
      end
      union = lists.inject { |un, i| un + i }
      return do_you_mean(bot, chat) if union.empty?
      xsection = lists.inject { |intersection, i| intersection & i }
      arr = xsection.empty? ? union.to_a : xsection.to_a
      if arr.size == 1
        person = @db.hgetall "#{Comingout::WIKI_DB}:#{arr.first}"
        msg = "<a href='#{person['uri']}'>#{person['name']}</a>\n"
        msg << "<b>Coming out:</b> <i>#{person['note']}</i>"
      else
        msg = "There are #{arr.size} persons with given name:\n"
        arr.each_with_index do |db_index, counter|
          person = @db.hgetall "#{Comingout::WIKI_DB}:#{db_index}"
          msg << "#{counter + 1}. #{person['name']}\n"
        end
      end
      msg
    end
  end
end
