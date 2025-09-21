class User < ApplicationRecord
  has_many :bulletins, dependent: :nullify

  def self.ransackable_attributes(_auth = nil)
    %w[email name id created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end
end
