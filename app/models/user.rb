# frozen_string_literal: true

class User < ApplicationRecord
  has_many :bulletins, dependent: :nullify
  has_many :favorites, dependent: :destroy
  has_many :oauth_identities, dependent: :destroy

  def self.ransackable_attributes(_auth = nil)
    %w[email name id created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end
end
