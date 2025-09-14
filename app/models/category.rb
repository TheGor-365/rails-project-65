class Category < ApplicationRecord
  has_many :bulletins, dependent: :restrict_with_exception

  validates :name, presence: true
end
