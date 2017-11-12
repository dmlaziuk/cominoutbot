module Comingout
  DB = 'lgbt'.freeze
  DB_INDEX = 'lgbt:index'.freeze
  DB_IMDB = 'lgbt:imdb'.freeze
  DB_WIKI = 'lgbt:wiki'.freeze
  DB_RU_WIKI = 'lgbt:ruwiki'.freeze
  FERRET = '.lgbt'.freeze
  TELEGRAM_TOKEN = '468538105:AAGDePSk0XwZU7J2QvsLwBDU7i24adkVit4'.freeze
  RU_EN = {
      'А' => 'A', 'а' => 'a', 'Б' => 'B', 'б' => 'b', 'В' => 'V', 'в' => 'v', 'Г' => 'G', 'г' => 'g', 'Д' => 'D', 'д' => 'd',
      'Е' => 'E', 'е' => 'e', 'Ё' => 'Jo', 'ё' => 'jo', 'Ж' => 'Zh', 'ж' => 'zh', 'З' => 'Z', 'з' => 'z', 'И' => 'I',
      'и' => 'i', 'Й' => 'J', 'й' => 'j', 'К' => 'K', 'к' => 'k', 'Л' => 'L', 'л' => 'l', 'М' => 'M', 'м' => 'm', 'Н' => 'N',
      'н' => 'n', 'О' => 'O', 'о' => 'o', 'П' => 'P', 'п' => 'p', 'Р' => 'R', 'р' => 'r', 'С' => 'S', 'с' => 's', 'Т' => 'T',
      'т' => 't', 'У' => 'U', 'у' => 'u', 'Ф' => 'F', 'ф' => 'f', 'Х' => 'H', 'х' => 'h', 'Ц' => 'C', 'ц' => 'c', 'Ч' => 'Ch',
      'ч' => 'ch', 'Щ' => 'Shh', 'щ' => 'shh', 'Ш' => 'Sh', 'ш' => 'sh', 'Ы' => 'Y', 'ы' => 'y', 'Ь' => "''", 'ь' => "'",
      'Ъ' => '##', 'ъ' => '#', 'Э' => 'E', 'э' => 'e', 'Ю' => 'Ju', 'ю' => 'ju', 'Я' => 'Ja', 'я' => 'ja'
  }.freeze

  def self.translit(text)
    text.split('').map do |char|
      RU_EN[char] ? RU_EN[char] : char
    end.join('')
  end
end
