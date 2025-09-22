# frozen_string_literal: true

AdminPolicy = Struct.new(:user, :admin) do
  def access?
    user&.admin?
  end
end
