class AdminPolicy < Struct.new(:user, :admin)
  def access?
    user&.admin?
  end
end
