require 'telegram/bot'

class CominoutBot
  TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze
  ACTORS = 'actors:imdb'.freeze

  def initialize
    @db = Redis.new
    @actors = @db.smembers(ACTORS)
    @actors.map! { |actor| actor.force_encoding('utf-8') }
    @actors_dc = @actors.map(&:downcase)
  end

  def run
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        cmd = message.text.downcase
        case cmd
        when '/start'
          msg = "Hello, #{message.from.first_name}"
        when '/end'
          msg = "Bye, #{message.from.first_name}!"
        when '/list'
          msg = "All actors:\n" + @actors.join("\n")
        else
          variants = cmd.split(' ').permutation
          bool_variants = variants.map { |i| @actors_dc.include?(i.join(' ')) }
          msg = bool_variants.include?(true) ? 'Yes' : 'No'
        end
        bot.api.send_message(chat_id: message.chat.id, text: msg)
      end
    end
  end
end
