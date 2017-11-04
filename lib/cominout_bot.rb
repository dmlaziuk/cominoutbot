require 'telegram/bot'

class CominoutBot

  TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze

  def initialize; end

  def run
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        case message.text
        when '/start'
          bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
        when '/end'
          bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}!")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "I don't understand you :(")
        end
      end
    end
  end
end
