require 'telegram/bot'

class CominoutBot
  TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze
  ACTORS = 'actors:imdb'.freeze

  def initialize
    @db = Redis.new
  end

  def run
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        cmd = message.text
        case cmd
        when '/start'
          msg = "Hello, #{message.from.first_name}"
        when '/end'
          msg = "Bye, #{message.from.first_name}!"
        when '/list'
          actors = @db.smembers(ACTORS).map { |i| i.force_encoding('utf-8') }
          msg = "All actors:\n" + actors.join("\n")
        else
          msg = if @db.sismember(ACTORS, cmd)
                  'Yes'
                else
                  'No'
                end
        end
        bot.api.send_message(chat_id: message.chat.id, text: msg)
      end
    end
  end
end
