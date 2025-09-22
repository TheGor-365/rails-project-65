# frozen_string_literal: true

class BulletinPolicy < ApplicationPolicy
  def to_moderate?
    user.present? && record.user_id == user.id && record.may_to_moderate?
  end

  def archive?
    user.present? && record.user_id == user.id && record.may_archive?
  end

  def publish?
    user&.admin? && record.may_publish?
  end

  def reject?
    user&.admin? && record.may_reject?
  end
end
