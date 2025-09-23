# frozen_string_literal: true

module Web
  module Admin
    class BaseController < ApplicationController
      before_action :authenticate_admin!

      private

      def authenticate_admin!
        unless signed_in?
          redirect_to root_path, alert: 'Войдите в аккаунт' and return
        end
        unless current_user.admin?
          redirect_to root_path, alert: 'Недостаточно прав'
        end
      end
    end
  end
end
