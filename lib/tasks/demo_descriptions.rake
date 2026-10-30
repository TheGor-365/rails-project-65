# frozen_string_literal: true

require 'csv'
require 'fileutils'

namespace :demo do
  desc 'Preview or selectively replace Lorem ipsum in known local demo bulletins (APPLY=1 to update)'
  task descriptions: :environment do
    abort 'Demo descriptions may be updated only in development.' unless Rails.env.development?

    descriptions = {
      'Смартфон LG' => 'Смартфон LG для звонков, общения и повседневных приложений. Перед покупкой уточните состояние экрана и аккумулятора, комплектацию и возможность проверить устройство.',
      'Доставка пиццы' => 'Пицца для семейного ужина, встречи с друзьями или небольшого мероприятия. Варианты начинки, стоимость, доступность адреса и время доставки уточняйте перед заказом.',
      'Переезд' => 'Помощь с организацией квартирного или офисного переезда: упаковка, погрузка, перевозка вещей и разгрузка по согласованию. Маршрут, объём груза и условия работы уточняйте заранее.',
      'Доставка бургеров' => 'Бургеры для обеда, ужина или встречи с друзьями. Меню, стоимость, время приготовления и адрес доставки согласовываются при заказе.',
      'Макбук' => 'Ноутбук MacBook для учёбы, работы и повседневных задач. Модель, характеристики, состояние аккумулятора и наличие зарядного устройства уточняйте у продавца перед покупкой.',
      'Пальто' => 'Пальто для прохладной погоды и повседневных образов. Перед покупкой уточните размер, состав ткани, состояние вещи и условия передачи. Дополнительные фотографии можно запросить у продавца.',
      'Ноутбук' => 'Ноутбук для повседневной работы, учёбы и просмотра материалов. Точные характеристики, состояние батареи, комплектацию и возможность проверки уточняйте перед покупкой.',
      'Куртка зимняя' => 'Зимняя куртка для холодной погоды. Перед покупкой уточните размер, материал, состояние утеплителя и особенности посадки. При необходимости попросите дополнительные фотографии.'
    }.freeze

    candidates = Bulletin.where(title: descriptions.keys).order(:id).select do |bulletin|
      bulletin.description.to_s.match?(/\A\s*lorem ipsum\b/i)
    end

    puts "Найдено демонстрационных описаний для замены: #{candidates.size}"
    candidates.each do |bulletin|
      puts "  ID #{bulletin.id}: #{bulletin.title} -> #{descriptions.fetch(bulletin.title)}"
    end

    if ENV['APPLY'] != '1'
      puts 'Режим предварительного просмотра. Записи не изменены.'
      puts 'Для применения: APPLY=1 bin/rails demo:descriptions'
      next
    end

    if candidates.empty?
      puts 'Подходящих записей нет. Изменений не выполнено.'
      next
    end

    backup_path = Rails.root.join(
      'tmp', 'db-backups', "demo_descriptions_#{Time.current.utc.strftime('%Y%m%d_%H%M%S_%6N')}.csv"
    )
    FileUtils.mkdir_p(backup_path.dirname)
    CSV.open(backup_path, 'wb', write_headers: true, headers: %w[id title old_description]) do |csv|
      candidates.each { |bulletin| csv << [bulletin.id, bulletin.title, bulletin.description] }
    end

    Bulletin.transaction do
      candidates.each { |bulletin| bulletin.update!(description: descriptions.fetch(bulletin.title)) }
    end

    puts "Обновлено описаний: #{candidates.size}. Резервная копия исходных текстов: #{backup_path}"
  end
end
