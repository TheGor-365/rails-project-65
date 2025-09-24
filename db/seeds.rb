# frozen_string_literal: true

categories = %w[Услуги Одежда Электроника]
categories.each do |name|
  Category.find_or_create_by!(name: name)
end
