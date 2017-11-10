require 'set'
require 'telegram/bot'
require_relative 'parse_imdb'
require_relative 'parse_wikipedia'
require_relative 'translit'

module Comingout

  class Bot
    TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze

    def initialize
      @db = Redis.new
      @imdb_actors = @db.smembers(Comingout::IMDB_DB)
      @imdb_actors.map! { |actor| actor.force_encoding('utf-8') }
      @imdb_actors_downcase = @imdb_actors.map(&:downcase)
    end

    def run
      Telegram::Bot::Client.run(TOKEN) do |bot|
        bot.listen do |chat|
          cmd = chat.text.downcase
          case cmd
          when '/start'
            start_cmd(bot, chat)
          when '/end'
            end_cmd(bot, chat)
          when '/list'
            end_cmd(bot, chat)
          # list_cmd(bot, chat)
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

    def dialog_imdb(chat)
      # imdb
      cmd = chat.text.downcase
      variants = cmd.split(' ').permutation
      imdb_bool_variants = variants.map do |i|
        @imdb_actors_downcase.include?(i.join(' '))
      end
      imdb_bool_variants.include?(true) ? 'Yes' : nil
    end

    def do_you_mean(bot, chat, person, msg)
      answer = 'ok'
      say(bot, chat, "Do you mean <b>#{person}?</b>")
      bot.listen do |request|
        req = request.text.downcase
        answer = msg if %w[yes да].include?(req)
        break
      end
      answer
    end

    def dialog_wiki(bot, chat)
      chat_text = Comingout.translit(chat.text.downcase)
      commands = chat_text.split(' ')
      lists = commands.map do |word|
        Set.new @db.lrange "#{Comingout::WIKI_DB}:name:#{word}", 0, -1
      end
      union = lists.inject { |un, i| un + i }
      return nil if union.empty?
      xsection = lists.inject { |intersection, i| intersection & i }
      arr = xsection.empty? ? union.to_a : xsection.to_a
      if arr.size == 1
        person = @db.hgetall "#{Comingout::WIKI_DB}:#{arr.first}"
        msg = "<a href='#{person['uri']}'>#{person['name']}</a>"
        msg << "\n<b>Coming out:</b> <i>#{person['note']}</i>"
      else
        msg = "There are #{arr.size} persons with given name:\n"
        arr.each_with_index do |db_index, counter|
          person = @db.hgetall "#{Comingout::WIKI_DB}:#{db_index}"
          msg << "#{counter + 1}. #{person['name']}\n"
        end
      end
      msg
    end


    def dialog(bot, chat)
      msg = dialog_wiki(bot, chat)
      if msg
        say(bot, chat, msg)
        return
      end
      msg = dialog_imdb(chat)
      if msg
        say(bot, chat, msg)
        return
      end
      msg = 'Found no data'
      say(bot, chat, msg)
    end

    def start_cmd(bot, chat)
      msg = "Hello, #{chat.from.first_name}"
      say(bot, chat, msg)
    end

    def end_cmd(bot, chat)
      msg = "Bye, #{chat.from.first_name}!"
      say(bot, chat, msg)
    end

    def list_cmd(bot, chat)
      say(bot, chat, 'All IMDB actors:')
      say(bot, chat, @actors.join("\n"))
      say(bot, chat, 'All wikipedia persons:')
      msg = ''
      index = 1
      while @db.exists "#{Comingout::WIKI_DB}:#{index}"
        msg << @db.hget("#{Comingout::WIKI_DB}:#{index}", 'name')
        msg << "\n"
        if index % 100 == 0
          say(bot, chat, msg)
          msg = ''
        end
        index += 1
      end
      say(bot, chat, msg)
    end
  end

end
