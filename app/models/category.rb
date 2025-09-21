class Category < ApplicationRecord
  has_many :bulletins, dependent: :restrict_with_exception

  validates :name, presence: true

  def self.ransackable_attributes(_auth = nil)
    %w[name id created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end
end
