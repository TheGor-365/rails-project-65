class User < ApplicationRecord
  has_many :bulletins, dependent: :nullify
end
