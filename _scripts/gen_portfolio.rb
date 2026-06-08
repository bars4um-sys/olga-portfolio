#!/usr/bin/env ruby
# frozen_string_literal: true
#
# gen_portfolio.rb — генератор _data/portfolio.yml из images/portfolio/*/
#
# Источник правды: папка images/portfolio/<Название>/<slug>.{webp,jpg|png}
# Категория, лейбл и тайтл — в CATEGORY_MAP (правится руками).
#
# Использование:
#   ruby _scripts/gen_portfolio.rb
#   ruby _scripts/gen_portfolio.rb --out _data/portfolio.yml
#
# Зачем: добавление новой работы = "положил webp+jpg в папку → запустил скрипт".
# Без ручной правки HTML.

require "yaml"
require "fileutils"
require "pathname"

ROOT = File.expand_path("..", __dir__)
PORTFOLIO_DIR = File.join(ROOT, "images", "portfolio")
OUT_PATH = File.join(ROOT, "_data", "portfolio.yml")

# ----------------------------------------------------------------------------
# Маппинг папка → { category, label, title, tall? }
# Это единственное место, где задаётся, к какой категории фильтра
# относится папка и какой у неё общий заголовок/лейбл.
#
# Если в папке лежит .png (как в Сириус/korob.png) — это fallback.
# ----------------------------------------------------------------------------
CATEGORY_MAP = {
  "Зин" => { cat: "zine",    label: "Зин",    title: "Drink Me" },
  "Зеленый журнал" => { cat: "journal", label: "Журнал", title: "Зелёный журнал" },
  "Меридианы"      => { cat: "book",    label: "Книга",  title: "Меридианы" },
  "Греция"         => { cat: "book",    label: "Книга",  title: "Греция" },
  "Диплом"         => { cat: "book",    label: "Книга",  title: "Диплом «Why»" },
  "Постеры"        => { cat: "poster",  label: "Постер", title: nil },  # title из alt
  "Барометр"       => { cat: "poster",  label: "Постер", title: "Барометр" },
  "Сириус"         => { cat: "merch",   label: "Мерч",   title: "Сириус", first_tall: true },
  "Допы"           => { cat: "dop",     label: nil,      title: nil, auto_title: true },
}

# ----------------------------------------------------------------------------
# Спец-логика для папки «Допы»: у каждой картинки свой alt и тайтл,
# поэтому title берётся из alt-строки (а не из маппинга).
# Это нужно потому, что в Допах смешаны разные работы — типографический
# зин, мокап «Why», геометрический постер, акварель, «Руки с букетом», Brie Light.
# ----------------------------------------------------------------------------
DOPY_ALT_PREFIX = {
  "043a8a24" => { title: "Типографический зин", label: "Зин" },
  "1e10581d" => { title: "Книга «Why»",         label: "Книга" },
  "20eaef2b" => { title: "Геометрический постер", label: "Постер" },
  "2bfd5bd6" => { title: "Акварельный разворот",  label: "Иллюстрация" },
  "6fa98969" => { title: "Руки с букетом",        label: "Постер" },
  "e395bad5" => { title: "Brie Light",            label: "Постер" },
}

# ----------------------------------------------------------------------------
# Генерация alt-текста по имени файла и папке.
# alt берётся из справочника ниже (точная копия alt-ов из index.html),
# а если не нашли — генерируется из заголовка + имени файла.
# ----------------------------------------------------------------------------
ALT_BY_FILE = {
  # Зин
  "zin_1" => "Зин Drink Me — обложка",
  "zin_2" => "Зин Drink Me — страница",
  "zin_3" => "Зин Drink Me — разворот",
  "zin_4" => "Зин Drink Me — разворот",
  "zin_5" => "Зин Drink Me — страница",
  # Зеленый журнал
  "mag"   => "Зелёный журнал — разворот",
  "golf"  => "Зелёный журнал — статья",
  "jour_1" => "Зелёный журнал — разворот",
  "jour_2" => "Зелёный журнал — страница",
  # Меридианы
  "oblmer" => "Меридианы — обложка",
  "mer_1"  => "Меридианы — разворот",
  "mer_2"  => "Меридианы — страница",
  "mer_3"  => "Меридианы — разворот",
  "obrmer" => "Меридианы — оборот",
  # Греция
  "zabj_1" => "Греция — верстка",
  "zabj_2" => "Греция — разворот",
  "zabj_3" => "Греция — страница",
  # Диплом
  "мокап обложки" => "Диплом Why — обложка",
  "огб 1"         => "Диплом Why — страница",
  # Постеры
  "poster_1" => "Постер — типографика",
  "poster_2" => "Постер — дизайн",
  "poster_3" => "Постер — кино",
  "poster_4" => "Постер — серия",
  "poster_5" => "Серия постеров",
  "poster_6" => "Постер — дизайн",
  "poster_7" => "Постер — типографика",
  "poster_8" => "Постер — иллюстрация",
  # Барометр
  "tih_1" => "Барометр — иллюстрация",
  "tih_2" => "Барометр — иллюстрация",
  # Сириус
  "shopper" => "Сириус — шоппер",
  "obl"     => "Сириус — блокнот",
  "Tshirt"  => "Сириус — футболка",
  "book"    => "Сириус — книга",
  "korob"   => "Сириус — коробка",
  "note"    => "Сириус — записная книжка",
  # Допы — берём из DOPY_ALT_PREFIX
}

# Сортировка файлов внутри папки: естественная (tih_1 < tih_2 < tih_10).
# UUID-формат (Допы) сортируем лексикографически — natural_key на нём глючит.
def natural_key(s)
  return s if s =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-/  # UUID
  s.split(/(\d+)/).map { |p| p =~ /\A\d+\z/ ? p.to_i : p }
end

# Попарно находим webp + jpg/jpeg/png в папке.
# Возвращает [{src:, fallback:, alt:}] или nil, если webp нет.
def collect_items(folder_path, folder_name, config)
  files = Dir.children(folder_path).reject { |f| f.start_with?(".") }
  files = files.map(&:dup)  # снимаем frozen от Dir.children
  files.sort_by! { |f| natural_key(f) }

  webps = files.select { |f| f.end_with?(".webp") }.sort_by { |f| natural_key(f) }

  items = []
  webps.each do |webp_name|
    base = webp_name.sub(/\.webp\z/, "")
    fallback = files.find { |f| f == "#{base}.jpg" } ||
               files.find { |f| f == "#{base}.jpeg" } ||
               files.find { |f| f == "#{base}.png" }
    next unless fallback

    alt = ALT_BY_FILE[base] || "#{config[:title] || folder_name} — #{base}"

    items << {
      "src"      => "images/portfolio/#{folder_name}/#{webp_name}",
      "fallback" => "images/portfolio/#{folder_name}/#{fallback}",
      "alt"      => alt
    }
  end
  items
end

# ----------------------------------------------------------------------------
# Главный цикл: обходим папки в фиксированном порядке, чтобы вывод
# был стабильным при пересборке.
# ----------------------------------------------------------------------------
def build_yaml
  folders = Dir.children(PORTFOLIO_DIR)
                .select { |f| File.directory?(File.join(PORTFOLIO_DIR, f)) }
                .sort_by { |f| natural_key(f) }

  # Приоритетный порядок (как был в index.html):
  order = CATEGORY_MAP.keys
  folders.sort_by { |f| [order.index(f) || 999, f] }

  groups = []
  folders.each do |folder|
    config = CATEGORY_MAP[folder]
    if config.nil?
      warn "[!] Папка #{folder.inspect} не в CATEGORY_MAP — пропускаю."
      next
    end

    items = collect_items(File.join(PORTFOLIO_DIR, folder), folder, config)
    if items.empty?
      warn "[!] В папке #{folder.inspect} не нашлось .webp+.jpg — пропускаю."
      next
    end

    group = {
      "folder"        => folder,
      "category"      => config[:cat],
      "category_label" => config[:label],
      "title"         => config[:title],
      "items"         => items
    }

    # Спец-логика для «Допы»: у каждой картинки свой title/label
    if config[:auto_title]
      items.each do |item|
        prefix = item["src"].split("/").last.split("-").first  # первые 8 символов uuid
        meta = DOPY_ALT_PREFIX[prefix]
        if meta
          item["title"] = meta[:title]
          item["label"] = meta[:label]
        else
          warn "[!] Не нашёл DOPY_ALT_PREFIX для #{item['src']} — title будет пустым."
        end
      end
    end

    if config[:first_tall]
      group["tall"] = true  # legacy: первая карточка Сириуса была с portfolio-card--tall
    end

    groups << group
  end

  groups
end

# ----------------------------------------------------------------------------
# Ручной YAML-эмиттер, чтобы файл был читаемым (психологический комфорт).
# YAML.dump выдаёт "---" в начале, что Jekyll не любит для _data.
# ----------------------------------------------------------------------------
def emit_yaml(groups)
  out = +"# Автогенерация: _scripts/gen_portfolio.rb\n"
  out << "# Источник: images/portfolio/*/. Правь маппинг в CATEGORY_MAP, не тут.\n"
  out << "# Пересборка: ruby _scripts/gen_portfolio.rb\n\n"

  groups.each_with_index do |g, i|
    out << "# #{i + 1}. #{g['folder']} (#{g['items'].size} шт.)\n"
    out << "- folder: #{g['folder'].inspect}\n"
    out << "  category: #{g['category']}\n"
    out << "  category_label: #{g['category_label'].inspect}\n" if g['category_label']
    out << "  title: #{g['title'].inspect}\n" if g['title']
    out << "  tall: true\n" if g['tall']

    # Спец-секция для Допов: per-item title/label
    if g['category'] == 'dop'
      out << "  items:\n"
      g['items'].each do |item|
        out << "    - src: #{item['src'].inspect}\n"
        out << "      fallback: #{item['fallback'].inspect}\n"
        out << "      alt: #{item['alt'].inspect}\n"
        out << "      title: #{item['title'].inspect}\n"
        out << "      label: #{item['label'].inspect}\n" if item['label']
      end
    else
      out << "  items:\n"
      g['items'].each do |item|
        out << "    - src: #{item['src'].inspect}\n"
        out << "      fallback: #{item['fallback'].inspect}\n"
        out << "      alt: #{item['alt'].inspect}\n"
      end
    end

    out << "\n"
  end

  out
end

# ----------------------------------------------------------------------------
# Точка входа
# ----------------------------------------------------------------------------
out_path = ARGV.find { |a| a.start_with?("--out=") }&.split("=", 2)&.last || OUT_PATH

groups = build_yaml
total  = groups.sum { |g| g["items"].size }

FileUtils.mkdir_p(File.dirname(out_path))
File.write(out_path, emit_yaml(groups))

puts "OK  → #{Pathname.new(out_path).relative_path_from(Pathname.new(ROOT))}"
puts "    #{groups.size} папок, #{total} карточек"
