# frozen_string_literal: true

class BulletinPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def show?
    record.state == 'published' || owner?
  end

  def new?
    create?
  end

  def create?
    user.present?
  end

  # Нужно для GET /bulletins/:id/edit
  def edit?
    owner?
  end

  # Нужно для PATCH/PUT /bulletins/:id
  def update?
    owner?
  end

  def to_moderate?
    owner?
  end

  def archive?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
