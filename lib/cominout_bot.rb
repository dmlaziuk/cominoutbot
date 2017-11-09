require 'telegram/bot'

class CominoutBot
  TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze
  IMDB_DB = 'lgbt:imdb'.freeze
  WIKI_DB = 'lgbt:wiki'.freeze

  def initialize
    @db = Redis.new
    @actors = @db.smembers(IMDB_DB)
    @actors.map! { |actor| actor.force_encoding('utf-8') }
    @actors_dc = @actors.map(&:downcase)
  end

  def run
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        cmd = message.text.downcase
        case cmd
        when '/start'
          start_cmd(bot, message)
        when '/end'
          end_cmd(bot, message)
        when '/list'
          list_cmd(bot, message)
        else
          dialog(bot, message)
        end
      end
    end
  end

  private

  def dialog(bot, message)
    variants = cmd.split(' ').permutation
    bool_variants = variants.map { |i| @actors_dc.include?(i.join(' ')) }
    msg = bool_variants.include?(true) ? 'Yes' : 'No'
    bot.api.send_message(chat_id: message.chat.id, text: msg)
  end

  def start_cmd(bot, message)
    msg = "Hello, #{message.from.first_name}"
    bot.api.send_message(chat_id: message.chat.id, text: msg)
  end

  def end_cmd(bot, message)
    msg = "Bye, #{message.from.first_name}!"
    bot.api.send_message(chat_id: message.chat.id, text: msg)
  end

  def list_cmd(bot, message)
    msg = "All IMDB actors:\n"
    bot.api.send_message(chat_id: message.chat.id, text: msg)
    msg = @actors.join("\n")
    bot.api.send_message(chat_id: message.chat.id, text: msg)
    msg = "All wikipedia persons:\n"
    bot.api.send_message(chat_id: message.chat.id, text: msg)
    msg = ''
    index = 1
    while @db.exists "#{WIKI_DB}:#{index}"
      msg << @db.hget("#{WIKI_DB}:#{index}", 'name')
      msg << "\n"
      if index % 100 == 0
        bot.api.send_message(chat_id: message.chat.id, text: msg)
        msg = ''
      end
      index += 1
    end
    bot.api.send_message(chat_id: message.chat.id, text: msg)
  end
end
